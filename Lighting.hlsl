#pragma once

#include "Math.hlsl"

struct PBRSurfaceData
{
    half3   albedo;
    half    opacity;
    half3   emission;
    half    metallic;
    half    smoothness;
    half    occlusion;
    half3    F0;
    
    half    alphaClipThreshold;
    half3   normalTS;
    float2  lightMapUV;
};

struct PBRLightData
{
    half3 normalWS;
    float3 positionWS;
    float3 positionSSNor;
    half3 viewDirWS;
    half3 reflectDirWS;

    Light   mainLight;
    int     additionalLightCount;
    half3   bakedIndirectDiffuse;   // raw color from light probe or light map
    half3   bakedIndirectSpecular;  // raw color from reflection probe
    
    float4 shadowCoord;
};

struct PBRBRDFData
{
    half3   albedo;
    half    preRoughness;
    half    roughness;
    half    roughness2;
    half    F0;
};

void InitBRDFData(inout PBRBRDFData brdfData, PBRSurfaceData surfaceData)
{
    brdfData.albedo = surfaceData.albedo;
    brdfData.preRoughness = PerceptualSmoothnessToPerceptualRoughness(surfaceData.smoothness);
    brdfData.roughness = max(PerceptualRoughnessToRoughness(brdfData.preRoughness), HALF_MIN_SQRT);
    brdfData.roughness2 = max(Pow2(brdfData.roughness), HALF_MIN);
    brdfData.F0 = surfaceData.F0;
}

// GGX / Trowbridge-Reitz
float GGXDistribution(float NoH, float roughness2)
{
    float d = (NoH * roughness2 - NoH) * NoH + 1; // 2 mad
    
    return roughness2 / (PI * d * d);         // 4 mul, 1 rcp
}
float GGXGeometry(float roughness2, float NoL, float NoV)
{
    float k = Pow2(1 + sqrt(roughness2)) / 8;
    float G1 = NoL * rcp(lerp(NoL, 1, k));
    float G2 = NoV * rcp(lerp(NoV, 1, k));

    return G1 * G2;
}
float IndirectGGXGeometry(float roughness2, float NoL, float NoV)
{
    float k = Pow2(sqrt(roughness2)) / 2;
    float G1 = NoL * rcp(lerp(NoL, 1, k));
    float G2 = NoV * rcp(lerp(NoV, 1, k));

    return G1 * G2;
}
// Schlick Fresnel from unity
float3 SchlickFresnel(float HoL, float3 F0)
{
    return F0 + (1 - F0) * Pow5(1 - HoL);
}
// BRDF直接光
float3 FinalBRDFDirect(inout PBRBRDFData brdfData, PBRSurfaceData surfaceData, Light light, PBRLightData lightData)
{
    float3 lightDirWS = SafeNormalize(light.direction);
    float3 halfDir = SafeNormalize(float3(lightData.viewDirWS) + float3(lightDirWS));
    float NoH = max(saturate(dot(lightData.normalWS, halfDir)), 0.0001f);
    float NoL = max(saturate(dot(lightData.normalWS, lightDirWS)), 0.0001f);
    float NoV = max(saturate(dot(lightData.normalWS, lightData.viewDirWS)), 0.0001f);
    float HoL = max(saturate(dot(halfDir, lightDirWS)), 0.0001f);
    
    float D = GGXDistribution(NoH, brdfData.roughness2);
    float G = GGXGeometry(brdfData.roughness2, NoL, NoV);
    float3 F = SchlickFresnel(HoL, brdfData.F0);

    float3 BRDFspecularTerm = D * G * F / (4 * NoL * NoV);
    float3 specularColor = BRDFspecularTerm * light.color * NoL * PI * light.distanceAttenuation * light.shadowAttenuation;   // 对半球积分需要加上PI

    float3 KS = F;
    float3 KD = (1 - KS) * (1 - surfaceData.metallic);
    float3 diffuseColor = KD * light.color * NoL * surfaceData.albedo * light.distanceAttenuation;   // 对半球积分抵消PI.不要shadowAttenuation

    return specularColor + diffuseColor;
}

// BRDF间接光Diffuse
// 取最近的四个Light Probe
// 采样lightProbe
float3 SHIndirectDiffuse(half3 normalWS)
{
    float4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;

    float3 result = SampleSH9(SHCoefficients, normalWS);
    return max(0.f, result);
}
// BRDF漫反射因子
float3 IndirectSchlickFresnel(PBRBRDFData brdfData, float NoV)
{
    float temp = Pow5(1 - NoV);
    return brdfData.F0 + temp * saturate(1 - brdfData.roughness - brdfData.F0);
}
float3 FinalIndirectDiffuse(PBRBRDFData brdfData, PBRLightData lightData, PBRSurfaceData surfaceData)
{
    float3 result = 0.f;
    #if defined (LIGHTMAP_ON)
    result = SampleLightmap(surfaceData.lightMapUV, lightData.normalWS);
    #else
    // 计算球谐函数
    float NoV = saturate(dot(lightData.normalWS, lightData.viewDirWS));
    
    float3 SHColor = SHIndirectDiffuse(lightData.normalWS);
    float3 IndirectKS = IndirectSchlickFresnel(brdfData, NoV);
    float3 IndirectKD = (1 - IndirectKS) * (1 - surfaceData.metallic);
    result = SHColor * IndirectKD * brdfData.albedo;
    #endif

    return result;
}

// BRDF间接光Specular
// 采样IBL
float3 IndirectSpecularCube(float3 normalWS, float3 viewDirWS, float roughness, float AO)
{
    float3 reflectDirWS = reflect(-viewDirWS, normalWS);
    roughness = roughness * (1.7f - 0.7f * roughness);  // roughness非线性需要调整
    float mipLevel = roughness * 6; // roughness分为7个level
    float4 specularColor = SAMPLE_TEXTURE2D_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, mipLevel);   // 采样Mipmap
    #if !defined(UNITY_USE_NATIVE_HDR)
    return DecodeHDREnvironment(specularColor, unity_SpecCube0_HDR) * AO;   // 解码。以a通道(环境贴图定义的系数)乘以高光颜色
    #else
    return specularColor.xyz * AO;
    #endif
}
// BRDF镜面反射因子
float3 IndirectSpecularFactor(float roughness, float smoothness, float3 specularTerm, float3 F0, float NoV)
{
    #ifdef UNITY_COLORSPACE_GAMMA
    float surReduction = 1 - 0.28f * roughness, roughness;
    #else
    float surReduction = 1 / (roughness * roughness + 1);
    #endif

    #ifdef SHADER_API_GLES
    float reflectivity = BRDFSpecular.x;
    #else
    float reflectivity = max(max(specularTerm.x, specularTerm.y), specularTerm.z);
    #endif

    float grazingTSection = saturate(reflectivity + smoothness);
    float Fre = Pow4(1 - NoV);

    return lerp(F0, grazingTSection, Fre) * surReduction;
}
float3 FinalIndirectSpecular(PBRBRDFData brdfData, PBRLightData lightData, PBRSurfaceData surfaceData, Light light)
{
    float3 lightDirWS = SafeNormalize(light.direction);
    float3 halfDir = SafeNormalize(float3(lightData.viewDirWS) + float3(lightDirWS));
    float NoH = max(saturate(dot(lightData.normalWS, halfDir)), 0.0001f);
    float NoL = max(saturate(dot(lightData.normalWS, lightDirWS)), 0.0001f);
    float NoV = max(saturate(dot(lightData.normalWS, lightData.viewDirWS)), 0.0001f);
    float HoL = max(saturate(dot(halfDir, lightDirWS)), 0.0001f);

    float D = GGXDistribution(NoH, brdfData.roughness2);
    float G = IndirectGGXGeometry(brdfData.roughness2, NoL, NoV);
    float3 F = SchlickFresnel(HoL, brdfData.F0);

    float3 BRDFspecularTerm = D * G * F / (4 * NoL * NoV);

    float3 specularColor = IndirectSpecularCube(lightData.normalWS, lightData.viewDirWS, brdfData.roughness, surfaceData.occlusion);
    float3 specularFactor = IndirectSpecularFactor(brdfData.roughness, surfaceData.smoothness, BRDFspecularTerm, surfaceData.F0, NoV);

    return specularColor * specularFactor;
}

// 最终求得的间接光
float3 FinalBRDFIndirect(PBRBRDFData brdfData, PBRLightData lightData, PBRSurfaceData surfaceData, Light light)
{
    return FinalIndirectDiffuse(brdfData, lightData, surfaceData) + FinalIndirectSpecular(brdfData, lightData, surfaceData, light);
}

// 经验模型
half3 BlinnPhong(Light light, half3 diffuseColor, float NoL, float NoH, half gloss)
{
    half3 diffuse = diffuseColor * NoL * light.color * light.shadowAttenuation * light.distanceAttenuation;
    half3 specular = light.color * pow(NoH, gloss);
    half3 ambient = _GlossyEnvironmentColor.rgb;

    half3 resultColor = diffuse + specular + ambient;

    return resultColor;
}


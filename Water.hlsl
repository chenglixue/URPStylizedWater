#pragma once

// all copied from PBR shader graph's generated code
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "../Library/Lighting.hlsl"
#include "../Library/MaterialHelper.hlsl"
#include "../Library/Math.hlsl"

CBUFFER_START(UnityPerMaterial)
half _Metallic;
half _Smoothness;
half _Occlusion;
half3 _F0;
half4 _EmissionTint;
half _EmissionScale;
half _Cutoff;

half _DepthFade;
half4 _ShallowColor;
half4 _DeepColor;
half4 _HorizonColor;
half _HorizonFresnelExp;

half _NormalIntensity;
half _Normal1Scale;
half _Normal2Scale;
half _Normal1Speed;
half _Normal2Speed;

half _RefractTiling;
half _RefractIntensity;
half _RefractSpeed;

half _ReflectDistortIntensity;
half _SSRPColorScale;
int _EnvironmentMipMapLevel;
half _EnvironmentColorScale;
half _ReflectFresnelExp;

half _CausticTiling;
half2 _CausticSpeed;
half _CausticRange;
half _ShoreCausticTransparent;
half _CausticTint;

half _FoamDepthFade;
half _FoamFade;
half _FoamSpeed;
half _FoamTiling;
half _FoamCutoff;
half4 _FoamTint;

half _Steepness;
half _WaveLength;
half _G;
half4 _WindDirection;
CBUFFER_END
half3 _LightDirection;

TEXTURE2D(_NormalTex);                              SAMPLER(sampler_NormalTex);
TEXTURE2D(_EmissionTex);                            SAMPLER(sampler_EmissionTex);
TEXTURE2D(_OpacityMaskTex);                         SAMPLER(sampler_OpacityMaskTex);
TEXTURE2D(_MetallicR_OcclusionG_SmoothnessA_Tex);   SAMPLER(sampler_MetallicR_OcclusionG_SmoothnessA_Tex);
//float4 unity_LightmapST;  //内置光照贴图的缩放和偏移   sampler2D unity_Lightmap;  //内置光照贴图
TEXTURE2D(_ResultRT);                               SAMPLER(sampler_ResultRT);
TEXTURE2D(_CausticTex);                             SAMPLER(sampler_CausticTex);
TEXTURE2D(_FoamTex);                                SAMPLER(sampler_FoamTex);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Struct
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
struct VSInput
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;

    float2 uv : TEXCOORD0;
    float2 uv2 : TEXCOORD1;
    float2 uv3 : TEXCOORD2;
    float2 uv4 : TEXCOORD3;
    float2 uv5 : TEXCOORD4;
    float2 uv6 : TEXCOORD5;
    float2 uv7 : TEXCOORD6;
    float2 uv8 : TEXCOORD7;

    UNITY_VERTEX_INPUT_INSTANCE_ID  // SV_InstanceID
};

struct PSInput
{
    float2 uv : TEXCOORD0;
    float2 uv2 : TEXCOORD1;
    float4 uv34 : TEXCOORD2;
    float4 uv56 : TEXCOORD3;
    float4 uv78 : TEXCOORD4;

    float4 positionWSAndFogFactor : TEXCOORD5;
    float4 positionCS : SV_POSITION;
    half3 normalWS : NORMAL;
    half3 tangentWS : TANGENT;
    half3 bitTangentWS : TEXCOORD6;

    float4 positionSS : TEXCOORD7;
    half3 viewDirWS : TEXCOORD8;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Main Pass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void GerstnerWave(inout float3 positionOS, inout float3 tangentWS, inout float3 binormalWS, half direction)
{
    direction = direction * 2 - 1;
    float2 d = normalize(float2(cos(3.14 * direction), sin(3.14 * direction)));	
    float k = 2 * 3.14 / _WaveLength;	// 频率周期
    float f = k * (dot(d, positionOS.xz) - _G * _Time.y);	// sin/cos参数
    float a = _Steepness / k;	// 振幅(防止打结)

    tangentWS += float3(
    -d.x * d.x * (_Steepness * sin(f)),
    d.x * (_Steepness * cos(f)),
    -d.x * d.y * (_Steepness * sin(f))
    );

    binormalWS += float3(
    -d.x * d.y * (_Steepness * sin(f)),
    d.y * (_Steepness * cos(f)),
    -d.y * d.y * (_Steepness * sin(f))
    );

    positionOS += float3(
    d.x * (a * cos(f)),
    a * sin(f),
    d.y * (a * cos(f))
    );
}
void GerstnerWave4(inout float3 positionOS, float3 normalWS)
{
    _Steepness = max(0.h, _Steepness);
    _WaveLength = max(0.0001h, _WaveLength);
    _G = max(0.h, _G);
    
    float3 tangent = float3(1, 0, 0);
    float3 binormal = float3(0, 0, 1);

    GerstnerWave(positionOS, tangent, binormal, _WindDirection.x);
    GerstnerWave(positionOS, tangent, binormal, _WindDirection.y);
    GerstnerWave(positionOS, tangent, binormal, _WindDirection.z);
    GerstnerWave(positionOS, tangent, binormal, _WindDirection.w);

    normalWS += cross(tangent, binormal);
}
void BuildVSOutputData(inout PSInput o, VSInput i, bool isExtraCustomPass = false)
{
    #if defined (_WAVE_ON)
    GerstnerWave4(i.positionOS, i.normalOS);
    #endif
    
    const VertexPositionInputs positionInput = GetVertexPositionInputs(i.positionOS.xyz);
    o.positionCS = positionInput.positionCS;
    o.positionSS = ComputeScreenPos(o.positionCS);
    float fogFactor = ComputeFogFactor(o.positionCS.z);
    o.positionWSAndFogFactor = float4(positionInput.positionWS, fogFactor);

    const VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS, i.tangentOS);
    o.normalWS = normalInput.normalWS;
    o.tangentWS = normalInput.tangentWS;
    o.bitTangentWS = normalInput.bitangentWS;
    o.viewDirWS = GetWorldSpaceViewDir(positionInput.positionWS);

    o.uv = i.uv;
    #if defined (_LIGHT_MAP_ON)
    o.uv2 = i.uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
    #else
    o.uv2 = i.uv2;
    #endif
    o.uv34 = float4(i.uv3, i.uv4);
    o.uv56 = float4(i.uv5, i.uv6);
    o.uv78 = float4(i.uv7, i.uv8);
}

PSInput VS(VSInput i, bool isExtraCustomPass = false)
{
    PSInput o = (PSInput)0;

    // GPU Instance
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_TRANSFER_INSTANCE_ID(i, o);

    BuildVSOutputData(o, i);

    return o;
}

PSInput VSUniversalForward(VSInput i)
{
    return VS(i);
}
PSInput VSCustomPass(VSInput i)
{
    return VS(i, true);
}

float3 GetScenePos(float4 positionSS, float3 viewDirWS, float2 uv)
{
    float3 result = 0.f;

    half depth = SampleSceneDepth(uv);
    half sceneDepth = LinearEyeDepth(depth, _ZBufferParams);
    result = -viewDirWS / positionSS.w * sceneDepth;
    result += GetCameraPositionWS();

    return result;
}
float2 GetRefractUV(float3 positionWS, float4 positionSS, float2 positionSSNor, float3 viewDirWS, float2 uv)
{
    float2 result = float2(0.f, 0.f);
    _RefractIntensity = max(0.f, _RefractIntensity) / 100.h;
    _RefractTiling = max(0.f, _RefractTiling) / 100.h;
    
    result += Panner(uv * rcpFastNR1(_RefractTiling), _Time.y, float2(_RefractSpeed, _RefractSpeed));
    result = FinalGradientNoise(result);
    result = RemapFloat2(result, float2(0, 1), float2(-1, 1));
    result *= _RefractIntensity;
    result += positionSSNor;

    // 避免不该出现的折射效果
    float3 scenePos = GetScenePos(positionSS, viewDirWS, result);
    result = (positionWS - scenePos).y >= 0.f ? result : positionSSNor;

    return result;
}
half GetDepthFade(float3 positionWS, float4 positionSS, float3 viewDirWS, float2 refractUV)
{
    half result = 0.h;
    
    float3 scenePos = GetScenePos(positionSS, viewDirWS, refractUV);
    result = (positionWS - scenePos).y;
    result = saturate(result / _DepthFade);

    return result;
}
half4 GetSurfaceAlbedo(PSInput psInput, half depthFade)
{
    half4 result = half4(0.h, 0.h, 0.h, 0.h);

    float horizonFrensel = Fresnel(psInput.normalWS, SafeNormalize(psInput.viewDirWS), _HorizonFresnelExp);
    
    result = HSVLerp(_ShallowColor, _DeepColor, depthFade);
    result = HSVLerp(result, _HorizonColor, horizonFrensel);

    return saturate(result);
}
half3 GetRefract(float2 refractUV)
{
    half3 result = half3(0.h, 0.h, 0.h);
    
    half3 sceneColor = SampleSceneColor(refractUV);
    
    result = sceneColor;

    return result;
}
half3 GetReflect(float4 positionSS, half3 normalWS, half3 viewDirWS)
{
    half3 result = half3(0.h, 0.h, 0.h);

    float2 positionSSNor = positionSS.xy / positionSS.w;
    float2 uv = positionSSNor + normalWS.xy * max(0.f, _ReflectDistortIntensity) * (_ScreenParams.zw - 1.h);

    half3 SSRPColor = SAMPLE_TEXTURE2D(_ResultRT, sampler_ResultRT, uv).rgb * max(0.0001f, _SSRPColorScale);
    half3 skyBoxColor = GetEnvironmentColor(viewDirWS, normalWS, _EnvironmentMipMapLevel) * max(0.0001f, _EnvironmentColorScale);
    result += SSRPColor + skyBoxColor;

    return result;
}
half3 GetCaustic(half depthFade, float2 positionSSNor)
{
    half3 result = half3(0.h, 0.h, 0.h);
    _CausticTiling = max(0.0001h, _CausticTiling);
    _CausticRange = max(0.1h, _CausticRange);
    _ShoreCausticTransparent = max(0.h, _ShoreCausticTransparent);
    _CausticTint = max(0.h, _CausticTint);
    
    half rawDepth = SampleSceneDepth(positionSSNor);
    float3 positionWS = ComputeWorldSpacePosition(positionSSNor, rawDepth, UNITY_MATRIX_I_VP);
    
    half causticArea = saturate(exp(-depthFade / _CausticRange));
    
    float2 uv = positionWS.xz / _CausticTiling;
    float2 uv1 = Panner(uv, _Time.y / 10, half2(_CausticSpeed.x, _CausticSpeed.x));
    float2 uv2 = Panner(-uv, _Time.y / 10, half2(_CausticSpeed.y, _CausticSpeed.y));
    half3 causticTex1 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, uv1).rgb;
    half3 causticTex2 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, uv2).rgb;
    result = min(causticTex1, causticTex2) * _CausticTint;
    result *= causticArea;
    
    return result;
}
half3 GetFoam(half depthFade, float2 uv)
{
    half3 result = half3(0.h, 0.h, 0.h);

    _FoamDepthFade = max(0.0001h, _FoamDepthFade) / 10.h;
    _FoamTiling = max(0.0001h, _FoamTiling) / 10.h;

    half foamMask = depthFade / _FoamDepthFade + 0.1h;
    foamMask = smoothstep(foamMask, 1.h - _FoamFade, 1.h);
    foamMask = 1.h - foamMask;

    float2 foamUV = Panner(uv * _FoamTiling, _Time.y / 10.h, half2(_FoamSpeed, _FoamSpeed));
    half foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, foamUV).r;
    half cutOff = foamMask * _FoamCutoff;
    foamTex = step(cutOff, foamTex);
    
    half4 temp = _FoamTint * foamTex;
    result = temp.rgb * temp.a * foamMask;

    return result;
}

void SetDefaultSurfaceData(inout PBRSurfaceData surfaceData)
{
    // set default value
    surfaceData.albedo = 1.h;
    surfaceData.opacity = 1.h;
    surfaceData.metallic = 0.h;
    surfaceData.smoothness = 0.5h;
    surfaceData.occlusion = 1.h;
    surfaceData.emission = 0.h;
    
    surfaceData.alphaClipThreshold = 0.f;
    surfaceData.normalTS = half3(0.h, 0.h, 1.h);
}
void GetShadowCoord(inout PBRLightData lightData)
{
    lightData.shadowCoord = TransformWorldToShadowCoord(lightData.positionWS);
}
void GetMainLight(inout PBRLightData lightData)
{
    lightData.mainLight = GetMainLight(lightData.shadowCoord);
}
void GetAdditionLightCounts(inout PBRLightData lightData)
{
    lightData.additionalLightCount = GetAdditionalLightsCount();
}
void BuildLightData(inout PBRSurfaceData surfaceData, inout PBRLightData lightData, inout PSInput psInput)
{
    psInput.tangentWS = SafeNormalize(psInput.tangentWS);
    psInput.bitTangentWS = SafeNormalize(psInput.bitTangentWS);
    psInput.normalWS = SafeNormalize(psInput.normalWS);
    half3x3 TBN = half3x3(psInput.tangentWS, psInput.bitTangentWS, psInput.normalWS);
    
    lightData.normalWS = SafeNormalize(TransformTangentToWorld(surfaceData.normalTS, TBN));
    lightData.positionWS = psInput.positionWSAndFogFactor.xyz;
    lightData.viewDirWS = SafeNormalize(GetWorldSpaceViewDir(lightData.positionWS));
    lightData.reflectDirWS = SafeNormalize(reflect(-lightData.viewDirWS, lightData.normalWS));

    GetShadowCoord(lightData);
    GetMainLight(lightData);
    GetAdditionLightCounts(lightData);
}
void SetUserSurfaceAndLightData(inout PBRSurfaceData surfaceData, inout PBRLightData lightData, inout PSInput psInput, bool isExtraCustomPass = false, bool isCutoffEarlyExit = false)
{
    float2 uv = psInput.uv;
    float2 uv3 = psInput.uv34.xy;

    #if defined (LIGHTMAP_ON)
    surfaceData.lightMapUV = psInput.uv2;
    #endif

    float3 positionWS = psInput.positionWSAndFogFactor.xyz;
    float2 positionSSNor = psInput.positionSS.xy / psInput.positionSS.w;
    half3 viewDirUnNor = GetWorldSpaceViewDir(positionWS);

    #if defined (_NORMAL_ON)
    half3 normalTS1 = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, Panner(positionWS.xz / _Normal1Scale, _Time.y / 100, _Normal1Speed)), _NormalIntensity);
    half3 normalTS2 = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, Panner(positionWS.xz / _Normal2Scale, _Time.y / 100, _Normal2Speed)), _NormalIntensity);
    surfaceData.normalTS = WhiteOutBlendNormal(normalTS1, normalTS2);
    #endif
    BuildLightData(surfaceData, lightData, psInput);
    
    float2 refractUV = GetRefractUV(positionWS, psInput.positionSS, positionSSNor, viewDirUnNor, uv3);
    half defaultDepthFade = GetDepthFade(positionWS, psInput.positionSS, viewDirUnNor, positionSSNor);
    half refractDepthFade = GetDepthFade(positionWS, psInput.positionSS, viewDirUnNor, refractUV);
    
    half4 albedo = GetSurfaceAlbedo(psInput, refractDepthFade);
    surfaceData.albedo = albedo.rgb;
    surfaceData.opacity = albedo.a;

    #if defined (_MOSA_ON)
    half4 MOS = SAMPLE_TEXTURE2D(_MetallicR_OcclusionG_SmoothnessA_Tex, sampler_MetallicR_OcclusionG_SmoothnessA_Tex, uv);
    surfaceData.metallic = MOS.r;
    surfaceData.occlusion = MOS.g;
    surfaceData.smoothness = MOS.b;
    #else
    surfaceData.metallic = _Metallic;
    surfaceData.occlusion = _Occlusion;
    surfaceData.smoothness = _Smoothness;
    #endif

    surfaceData.F0 = lerp(_F0, surfaceData.albedo, surfaceData.metallic);

    #if defined (_EMISSION_ON)
    surfaceData.emission = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, uv).rgb * _EmissionTint.rgb * _EmissionTint.aaa;
    #else
    surfaceData.emission = 0;
    #endif

    #if defined(_REFRACT_ON)
    half3 refractColor = GetRefract(refractUV);
    surfaceData.albedo = lerp(albedo.rgb, refractColor, 0.5);
    #endif

    #if defined (_REFLECT_ON)
    half3 reflectColor = GetReflect(psInput.positionSS, lightData.normalWS, lightData.viewDirWS);
    surfaceData.albedo += reflectColor;
    #endif

    #if defined (_CAUSTIC_ON)
    half3 causticColor = GetCaustic(defaultDepthFade, positionSSNor);
    surfaceData.albedo += causticColor;
    #endif

    #if defined (_FOAM_ON)
    half3 foamColor = GetFoam(defaultDepthFade, positionWS.xz);
    surfaceData.albedo += foamColor;
    #endif

    if(isExtraCustomPass == true)
    {
        surfaceData.albedo = 0.h;
        surfaceData.smoothness = 0.h;
        surfaceData.metallic = 0.h;
        surfaceData.occlusion = 0.h;
    }
}
void ClampSurfaceData(inout PBRSurfaceData surfaceData)
{
    surfaceData.albedo = max(0, surfaceData.albedo);
    surfaceData.metallic = saturate(surfaceData.metallic);
    surfaceData.smoothness = saturate(surfaceData.smoothness);
    surfaceData.occlusion = saturate(surfaceData.occlusion);
    surfaceData.F0 = saturate(surfaceData.F0);
    surfaceData.normalTS = normalize(surfaceData.normalTS);
    surfaceData.opacity = saturate(surfaceData.opacity);
    surfaceData.alphaClipThreshold = saturate(surfaceData.alphaClipThreshold);
    surfaceData.emission = max(0, surfaceData.emission);
}
void BuildData(inout PBRSurfaceData surfaceData, inout PBRLightData lightData, inout PSInput psInput, bool isExtraCustomPass = false, bool isCutoffEarlyExit = false)
{
    SetDefaultSurfaceData(surfaceData);
    
    SetUserSurfaceAndLightData(surfaceData, lightData, psInput, isExtraCustomPass, isCutoffEarlyExit);

    ClampSurfaceData(surfaceData);
}

// 计算最终光照结果
half4 CalcLightingResult(PSInput psInput, PBRLightData lightData, PBRSurfaceData surfaceData)
{
    PBRBRDFData brdfData = (PBRBRDFData)0;
    InitBRDFData(brdfData, surfaceData);

    // 计算直接光照
    half3 result = FinalBRDFDirect(brdfData, surfaceData, lightData.mainLight, lightData);

    // 计算间接光照
    result += FinalBRDFIndirect(brdfData, lightData, surfaceData, lightData.mainLight);

    #if defined (_MULTIPLE_LIGHT_ON)
    // 计算额外光
    for(uint i = 0; i < lightData.additionalLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, lightData.positionWS, half4(1.h, 1.h, 1.h, 1.h));
        result += FinalBRDFDirect(brdfData, surfaceData, light, lightData);
        result += FinalBRDFIndirect(brdfData, lightData, surfaceData, light);
    }
    #endif

    result += surfaceData.emission * surfaceData.occlusion;

    float fogFactor = psInput.positionWSAndFogFactor.w;
    result = MixFog(result, fogFactor);

    return half4(result, surfaceData.opacity);
}

half4 PS(PSInput i, bool isExtraCustomPass = false, bool isCutoffEarlyExit = false)
{
    UNITY_SETUP_INSTANCE_ID(i); // 使得instance ID能够在shader中被访问
    
    half4 o = half4(0.f, 0.f, 0.f, 0.f);
    PBRSurfaceData surfaceData = (PBRSurfaceData)0;
    PBRLightData lightData = (PBRLightData)0;
    
    BuildData(surfaceData, lightData, i, isExtraCustomPass);
    if(isCutoffEarlyExit == true)
    {
        return 0;
    }
    o += CalcLightingResult(i, lightData, surfaceData);

    #if defined (_DEPTH_FADE_TEST_ON)
    float2 positionSSNor = i.positionSS.xy / i.positionSS.w;
    half3 viewDirUnNor = GetWorldSpaceViewDir(lightData.positionWS);
    float2 refractUV = GetRefractUV(lightData.positionWS, i.positionSS, positionSSNor, viewDirUnNor, i.uv);
    half depthFade = GetDepthFade(lightData.positionWS, i.positionSS, viewDirUnNor, refractUV);
    return half4(depthFade, depthFade, depthFade, 1.h);
    #endif

    #if defined (_OPACITY_TEST_ON)
    return half4(surfaceData.opacity, surfaceData.opacity, surfaceData.opacity, 1.h);
    #endif
    
    return o;
}
half4 PSUniversalForward(PSInput i) : SV_TARGET
{
    return PS(i);
}
half4 PSCutoffEarlyExit(PSInput i) : SV_TARGET
{
    return PS(i, false, true);
}
half4 PSCustomPass(PSInput i) : SV_TARGET
{
    return PS(i, true);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Shadow Pass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
PSInput VSShadow(VSInput vsInput)
{
    PSInput VSOutput;

    VSOutput.uv = vsInput.uv;

    VSOutput.normalWS = TransformObjectToWorldNormal(vsInput.normalOS);
    float3 positionWS = TransformObjectToWorld(vsInput.positionOS);
    Light mainLight = GetMainLight();
                
    VSOutput.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, VSOutput.normalWS, _LightDirection));
                
    #if UNITY_REVERSED_Z
    VSOutput.positionCS.z = min(VSOutput.positionCS.z, VSOutput.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    VSOutput.positionCS.z = max(VSOutput.positionCS.z, VSOutput.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif

    return VSOutput;
}


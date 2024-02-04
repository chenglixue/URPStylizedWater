#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

float4 TransformHClipToViewPort(float4 positionCS)
{
    float4 output = positionCS * 0.5f;
    output.xy = float2(output.x, output.y * _ProjectionParams.x) + output.w;
    output.zw = positionCS.zw;

    return output / output.w;
}

half CheapContrast(half In, half Contrast)
{
    return saturate(lerp(-Contrast, 1 + Contrast, In));
}

half Fresnel(float3 normalWS, float3 viewDirWS, float power)
{
    return pow(1.0 - saturate(dot(normalize(normalWS), normalize(viewDirWS))), power);
}

half3 WhiteOutBlendNormal(half3 normal1, half3 normal2)
{
    half3 result = half3(0.h, 0.h, 0.h);

    result = half3(normal1.xy + normal2.xy, normal1.z * normal2.z);
    result = SafeNormalize(result);

    return result;
}

// ------------------------------------------------------------------------------------------ UV --------------------------------------------------------------------------------------------
float2 Panner(float2 uv, float time, half2 speed = half2(1.h, 1.h))
{
    return uv + time * speed;
}

float4 RemapFloat4(float4 In, float2 InMinMax, float2 OutMinMax)
{
    float4 Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);

    return Out;
}

float2 RemapFloat2(float2 In, float2 InMinMax, float2 OutMinMax)
{
    float2 Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
    return Out;
}

// 三平面映射
float4 WorldAlignedTexture_XYZ(in Texture2D inputTex, sampler samplerInputTex, in float3 positionWS, in float3 normalWS, in half3 textureSize = 64.f, in half ProjectionTransitionContrast = 1.f)
{
    positionWS /= -abs(textureSize);

    half lerpAlpha1 = CheapContrast(abs(normalWS.r), ProjectionTransitionContrast);
    half lerpAlpha2 = CheapContrast(abs(normalWS.g), ProjectionTransitionContrast);
    
    half4 inputTex1 = SAMPLE_TEXTURE2D(inputTex, samplerInputTex, positionWS.yz);
    half4 inputTex2 = SAMPLE_TEXTURE2D(inputTex, samplerInputTex, positionWS.xz);
    half4 inputTex3 = SAMPLE_TEXTURE2D(inputTex, samplerInputTex, positionWS.xy);

    half4 outputTex = lerp(inputTex1, inputTex2, lerpAlpha1);
    outputTex = lerp(outputTex, inputTex3, lerpAlpha2);

    return outputTex;
}

float4 WorldAlignedTexture_XY(Texture2D inputTex, sampler samplerInputTex, float3 positionWS, half3 normalWSNor, half3 textureSize = 64.f, half ProjectionTransitionContrast = 1.f)
{
    positionWS /= -abs(textureSize);

    half lerpAlpha1 = CheapContrast(abs(normalWSNor.x), ProjectionTransitionContrast);

    half4 inputTex1 = SAMPLE_TEXTURE2D(inputTex, samplerInputTex, positionWS.yz);
    half4 inputTex2 = SAMPLE_TEXTURE2D(inputTex, samplerInputTex, positionWS.xz);

    half4 outputTex = lerp(inputTex1, inputTex2, lerpAlpha1);

    return outputTex;
}

float4 WorldAlignedTexture_Y(Texture2D inputTex, sampler samplerInputTex, float3 positionWS, half3 textureSize = 64.f)
{
    positionWS /= -abs(textureSize);
    
    half4 inputTex3 = SAMPLE_TEXTURE2D(inputTex, samplerInputTex, positionWS.xy);

    return inputTex3;
}

// ------------------------------------------------------------------------------------------ Color --------------------------------------------------------------------------------------------
half3 RGBToHSV(half3 In)
{
    half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    half4 P = lerp(half4(In.bg, K.wz), half4(In.gb, K.xy), step(In.b, In.g));
    half4 Q = lerp(half4(P.xyw, In.r), half4(In.r, P.yzx), step(P.x, In.r));
    half D = Q.x - min(Q.w, Q.y);
    half E = 1e-10;
    return half3(abs(Q.z + (Q.w - Q.y)/(6.0 * D + E)), D / (Q.x + E), Q.x);
}

half3 HSVToRGB(half3 In)
{
    half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    half3 P = abs(frac(In.xxx + K.xyz) * 6.0 - K.www);
    return In.z * lerp(K.xxx, saturate(P - K.xxx), In.y);
}

half4 HSVLerp(half4 A, half4 B, half T)
{
    A.xyz = RGBToHSV(A.xyz);
    B.xyz = RGBToHSV(B.xyz);

    half t = T; // used to lerp alpha, needs to remain unchanged

    half hue;
    half d = B.x - A.x; // hue difference

    if(A.x > B.x)
    {
        half temp = B.x;
        B.x = A.x;
        A.x = temp;

        d = -d;
        T = 1-T;
    }

    if(d > 0.5)
    {
        A.x = A.x + 1;
        hue = (A.x + T * (B.x - A.x)) % 1;
    }

    if(d <= 0.5) hue = A.x + T * d;

    half sat = A.y + T * (B.y - A.y);
    half val = A.z + T * (B.z - A.z);
    half alpha = A.w + t * (B.w - A.w);

    half3 rgb = HSVToRGB(half3(hue,sat,val));

    return half4(rgb, alpha);
}

half3 GetEnvironmentColor(half3 viewDirWS, half3 normalWS, int mipMapLevel)
{
    float3 reflectDirW = reflect(-viewDirWS, normalWS);

    return SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirW, mipMapLevel);
}

// ------------------------------------------------------------------------------------------ Depth --------------------------------------------------------------------------------------------
struct Depth
{
    float raw;
    float linear01;
    float eye;
};

Depth SampleDepth(float4 positionSS)
{
    float3 positionSSNor = float3(positionSS.xy / positionSS.w, positionSS.z);
    
    Depth depth = (Depth)0;

    depth.raw = SampleSceneDepth(positionSSNor.xy);
    depth.eye = LinearEyeDepth(depth.raw, _ZBufferParams);
    depth.linear01 = Linear01Depth(depth.raw, _ZBufferParams);

    return depth;
}

float GetRawDepth(Depth depth)
{
    return depth.raw;
}

float GetLinear01Depth(Depth depth)
{
    return depth.linear01;
}

float GetEyeDepth(Depth depth)
{
    return depth.eye;
}

float GetPixelDepth(float4 positionSS)
{
    return positionSS.w;
}

float DepthFade(float sceneDepth, float pixelDepth, half opacity, half depthFade = 100.h)
{
    half depthDiff = sceneDepth - pixelDepth;
    
    return opacity * saturate(depthDiff / depthFade);
}

// ------------------------------------------------------------------------------------------ 视差 --------------------------------------------------------------------------------------------
// 采样高度图, 获取高度数据
float GetHeight(float2 uv, Texture2D heightTex, sampler sampler_heightTex)
{
    // 必须为LOD,否则会报错
    return SAMPLE_TEXTURE2D_LOD(heightTex, sampler_heightTex, uv, 0).r;
}

float2 ParallaxOcclusionMapping(Texture2D heightTex, sampler sampler_heightTex, float2 uv, float4 positionCS, half3 viewDirTSNor, half heightRatio, half minLayer, half maxLayer)
{
    float numLayers = lerp(maxLayer, minLayer, abs(dot(half3(0.h, 0.h, 1.h), viewDirTSNor)));
    float layerHeight = 1.f / numLayers;  // 每层高度
    float currentLayerHeight = 0.f;

    // shift of texture coordinates for each layer
    float2 uvDelta = heightRatio * viewDirTSNor.xy / viewDirTSNor.z / numLayers;
    float2 currentUV = uv;

    float currentHeightTexValue = GetHeight(currentUV, heightTex, sampler_heightTex);
    while(currentLayerHeight < currentHeightTexValue)
    {
        currentUV -= uvDelta;   // shift of texture coordinates
        currentLayerHeight += layerHeight;  // to next layer
        currentHeightTexValue = GetHeight(currentUV, heightTex, sampler_heightTex); // new height
    }

    // last uv
    float2 lastUV = currentUV + uvDelta;

    // heights for lerp
    float nextHeight    = currentHeightTexValue - currentLayerHeight;
    float lastHeight    = GetHeight(lastUV, heightTex, sampler_heightTex) - currentLayerHeight + layerHeight;
    
    // proportions for lerp
    float weight = nextHeight / (nextHeight - lastHeight);

    // lerp uv
    float2 result = lastUV * weight + currentUV * (1.f-weight);

    // lerp depth values
    float parallaxHeight = currentLayerHeight + lastHeight * weight + nextHeight * (1.0 - weight);

    return result;
}

// ------------------------------------------------------------------------------------------ Noise --------------------------------------------------------------------------------------------
float2 GradientNoiseDir(float2 uv)
{
    uv = uv % 289;
    float x = (34 * uv.x + 1) * uv.x % 289 + uv.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}
float GradientNoise(float2 uv)
{
    float2 iuv = floor(uv);
    float2 fuv = frac(uv);
    float d00 = dot(GradientNoiseDir(iuv), fuv);
    float d01 = dot(GradientNoiseDir(iuv + float2(0, 1)), fuv - float2(0, 1));
    float d10 = dot(GradientNoiseDir(iuv + float2(1, 0)), fuv - float2(1, 0));
    float d11 = dot(GradientNoiseDir(iuv + float2(1, 1)), fuv - float2(1, 1));
    fuv = fuv * fuv * fuv * (fuv * (fuv * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fuv.y), lerp(d10, d11, fuv.y), fuv.x);
}
float FinalGradientNoise(float2 uv, float scale = 1.f)
{
    return GradientNoise(uv * scale) + 0.5f;
}
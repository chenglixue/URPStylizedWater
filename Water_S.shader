Shader "Water"
{
    Properties
    {
        [Header(Rendering Setting)]
        [Space(10)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", int) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Source", int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendDst("Blend Destination", int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp("Blend Operator", int) = 0
        [IntRange] _StencilRef("Stencil Ref", Range(0, 255)) = 0
        [IntRange] _StencilReadMask("Stencil Read Mask", Range(0, 255)) = 255
        [IntRange] _StencilWriteMask("Stencil Write Mask", Range(0, 255)) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilTestCompare("Stencil Test Compare", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp("Stencil Pass Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp("Stencil Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilDepthFailOp("Stencil Depth Test Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilBackTestCompare("Stencil Back Test Compare", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilBackPassOp("Stencil Back Pass Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilBackFailOp("Stencil Back Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilBackDepthFailOp("Stencil Back Depth Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilFrontTestCompare("Stencil Front Test Compare", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFrontPassOp("Stencil Front Pass Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFrontFailOp("Stencil Front Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFrontDepthFailOp("Stencil Front Depth Fail Operator", Int) = 0
        [Enum(Off, 0, On, 1)] _ZWriteEnable("ZWrite Mode", int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestCompare("ZTest Mode", int) = 4
        [Enum(UnityEngine.Rendering.ColorWriteMask)] _ColorMask("Color Mask", Int) = 15
        
        [Toggle] _MULTIPLE_LIGHT("Enable Multiple Light", Int) = 1
        [Toggle] LIGHTMAP("Enable Light Map", Int) = 1
        [Space(20)]
        
        [Header(PBR Setting)]
        [Space(10)]
        [Toggle] _MOSA("Enable MetallicR OcclusionG SmoothnessA", Int) = 0
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.0
        _Occlusion("Ambient Occlusion", Range(0.0, 1.0)) = 0.0
        [NoScaleOffset] _MetallicR_OcclusionG_SmoothnessA_Tex("MetallicR OcclusionG SmoothnessA Tex", 2D) = "black" {}
        _F0("F0", Vector) = (0.04, 0.04, 0.04, 0)
        [Space(20)]
        
        [Header(Normal Setting)]
        [Space(10)]
        [Toggle] _NORMAL("Enable NormalMap?", Int) = 1
        [Normal][NoScaleOffset] _NormalTex ("Normal Tex", 2D) = "bump" {}
        _NormalIntensity("Normal Intensity", Range(0, 1)) = 1
        _Normal1Scale("Normal1 Scale", Float) = 50
        _Normal2Scale("Normal2 Scale", Float) = 50
        _Normal1Speed("Normal1 Speed", Float) = -1.66
        _Normal2Speed("Normal2 Speed", Float) = 2.5
        [Space(20)]
        
        [Header(Emission Setting)]
        [Space(10)]
        [Toggle] _EMISSION("Enable Emission?", Int) = 1
        [NoScaleOffset] _EmissionTex("Emission Tex", 2D) = "black" {}
        [HDR]_EmissionTint("Emission Tint", Color) = (1, 1, 1, 1)
        _EmissionScale("Emission Scale", Range(0, 1)) = 0
        [Space(20)]
        
        [Header(Surface Color Setting)]
        [Space(10)]
        [Toggle] _DEPTH_FADE_TEST("Enable Depth Fade Test", Int) = 0
        [Toggle] _OPACITY_TEST("Enable Opacity Test", Int) = 0
        _DepthFade("Water Depth Fade", Range(0.0001, 10)) = 1
        _ShallowColor("Shallow Water Color", Color) = (0.05098018, 0.9607844, 0.8745099, 0.4)
        _DeepColor("Deep Water Color", Color) = (0, 0.7254902, 0.9411765, 0.8)
        [HDR]_HorizonColor("Horizon Water Color", Color) = (0.2232704, 0.3745591, 1, 0.5)
        _HorizonFresnelExp("Water Horizon Fresnel Exp", Range(0, 20)) = 14
        [Space(20)]
        
        [Header(Refract)]
        [Space(10)]
        [Toggle] _REFRACT("Enable Refract", Int) = 1
        _RefractTiling("Refract Tiling", Float) = 1
        _RefractSpeed("Refract Speed", Float) = 1
        _RefractIntensity("Refract Intensity", Float) = 1
        [Space(20)]
        
        [Header(Reflect)]
        [Toggle] _REFLECT("Enable Reflect", Int) = 1
        _ReflectDistortIntensity("Reflect Distort Intensity", Float) = 50
        _SSRPColorScale("SSRP Color Scale", Float) = 1
        [IntRange] _EnvironmentMipMapLevel("Environment MipMap Level", Range(0, 9)) = 0
        _EnvironmentColorScale("Environment Color Scale", Float) = 0.676
        _ReflectFresnelExp("Reflect Fresnel Exp", Float) = 1.48
        [Space(20)]
        
        [Header(Caustic)]
        [Toggle] _CAUSTIC("Enable Caustic", Int) = 1
        _CausticTex("Caustic Tex", 2D) = "black" {}
        _CausticTiling("Caustic Scale", Float) = 1
        _CausticSpeed("Caustic Speed", Vector) = (1, 1, 1, 1)
        _CausticRange("Caustic Range", Range(0, 1)) = 0
        _CausticTint("Caustic Tint", Float) = 1
        [Space(20)]
        
        [Header(Foam)]
        [Toggle] _FOAM("Enable Foam", Int) = 1
        [NoScaleOffset]_FoamTex("Foam Tex", 2D) = "black" {}
        _FoamDepthFade("Foam Depth Fade", Float) = 1
        _FoamFade("Foam Fade", Range(0, 1)) = 1
        _FoamSpeed("Foam Speed", Float) = 1
        _FoamTiling("Foam Tiling", Float) = 1
        _FoamCutoff("Foam Cutoff", Range(0, 1)) = 1
        _FoamTint("Foam Tint", Color) = (1, 1, 1, 1)
        [Space(20)]
        
        [Header(Wave)]
        [Toggle] _WAVE("Enable Wave", Int) = 0
        _Steepness("Steepness", Float) = 1
        _WaveLength("Wave Length", Float) = 1
        _G("g", Float) = 9.8
        _WindDirection("windDirection", Vector) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType"="Transparent" 
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
        }
        LOD 100
        
        HLSLINCLUDE
        // all pass need
        #pragma target 2.0
        #pragma multi_compile_fog           // 内置雾效 
        #pragma multi_compile_instancing    // gpu instance

        #pragma multi_compile _ LIGHTMAP_ON // 启用Lightmap
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED    // LightMap是否使用方向向量
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE // 烘焙的混合模式
        #pragma shader_feature_local _MULTIPLE_LIGHT_ON             // 启用多光源
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS                 // 计算主光源的阴影衰减
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE         // 计算主光源的阴影坐标
        #pragma multi_compile _ ADDITIONAL_LIGHT_CALCULATE_SHADOWS  // 计算额外光的阴影衰减和距离衰减
        #pragma multi_compile _ _SHADOWS_SOFT                       // 计算软阴影
        #pragma multi_compile __ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS   //计算阴影投射
        
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            
            Tags
            {
                "LightMode" = "UniversalForwardOnly"
            }
            Cull [_CullMode]
            Blend [_BlendSrc] [_BlendDst]
            BlendOp [_BlendOp]
            Stencil
            {
                Ref [_StencilRef]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
                
                Comp [_StencilTestCompare]
                Pass [_StencilPassOp]
                Fail [_StencilFailOp]
                ZFail [_StencilDepthFailOp]
                
                CompBack [_StencilBackTestCompare]
                PassBack [_StencilBackPassOp]
                FailBack [_StencilBackFailOp]
                ZFailBack [_StencilBackDepthFailOp]
                
                CompFront [_StencilFrontTestCompare]
                PassFront [_StencilFrontPassOp]
                FailFront [_StencilFrontFailOp]
                ZFailFront [_StencilFrontDepthFailOp]
            }
            ZWrite [_ZWriteEnable]
            ZTest [_ZTestCompare]
            ColorMask [_ColorMask]
            
            HLSLPROGRAM
            #pragma shader_feature_local _NORMAL_ON                     // 启用法线
            #pragma shader_feature_local _OPACITY_MASK_ON               // 启用cut off
            #pragma shader_feature_local _EMISSION_ON                   
            #pragma shader_feature_local _MOSA_ON
            #pragma shader_feature_local _DEPTH_FADE_TEST_ON            // 启用DepthFade测试
            #pragma shader_feature_local _OPACITY_TEST_ON               // 启用Opacity测试
            #pragma shader_feature_local _REFRACT_ON                    // 启用折射
            #pragma shader_feature_local _REFLECT_ON                    // 启用反射
            #pragma shader_feature_local _CAUSTIC_ON                    // 启用焦散
            #pragma shader_feature_local _FOAM_ON                       // 启用浪花
            #pragma shader_feature_local _WAVE_ON                       // 启用海浪
            
            #include_with_pragmas "Water.hlsl"
            
            #pragma vertex VSUniversalForward
            #pragma fragment PSUniversalForward
            
            ENDHLSL
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull Back
            
            HLSLINCLUDE
            #include"Water.hlsl"

            ENDHLSL
            
            HLSLPROGRAM
            #pragma vertex VSShadow
            #pragma fragment PSCutoffEarlyExit
            
            ENDHLSL
        }
        
        //DepthOnly pass, for rendering this shader into URP's _CameraDepthTexture
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ColorMask 0 
            
            HLSLINCLUDE
            #include "Water.hlsl"

            ENDHLSL
            
            HLSLPROGRAM
            #pragma vertex VSCustomPass
            #pragma fragment PSCutoffEarlyExit
            ENDHLSL
        }
    }
}

/*
Filamented Pixel Art is a shader designed for rendering PBR with pixel art.
It uses the same techniques as my Pixel Standard shader, but adapted for
Filamented.
https://gitlab.com/s-ilent/pixelstandard
*/
Shader "Silent/Filamented Extras/Pixel Art Filamented(Vertex Colors)"
{
    Properties
    {
        [CheckDFGTexture]
        [BlendModeSelector(_SrcBlend, _DstBlend, _CustomRenderQueue, _ZWrite, _AtoCmode)] _Mode ("__mode", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Int) = 2
        [HeaderEx(Base Material)]
        [ScaleOffset][SingleLine(_Color)]_MainTex("Albedo", 2D) = "white" {}
        [HideInInspector]_Color("Color", Color) = (1,1,1,1)
        _VertexColourScale("Vertex Colour Intensity", Range(0, 1)) = 1.0
        [Space]
        [SingleLine(_BumpScale)][Normal]_BumpMap("Normal", 2D) = "bump" {}
        [HideInInspector]_BumpScale("Normal Scale", Float) = 1
        [SingleLine]_MOESMap("MOES Map", 2D) = "white" {}
        [Space]
        _MetallicScale("Metallic", Range( 0 , 1)) = 0
        _OcclusionScale("Occlusion", Range( 0 , 1)) = 0
        _Emission("Emission Power", Float) = 0
        _SmoothnessScale("Smoothness", Range( 0 , 1)) = 0
        [Space]
        _EmissionColor("Emission Color", Color) = (1,1,1,1)
        [HeaderEx(Texture Animation)]
        [Toggle(_ANIMATED)] _Animated ("Texture Animation", Float) = 0
        [NoScaleOffset]_AnimationMainTex("Animated Albedo", 2DArray) = "white" {}
        [Enum(PingPong, 0, Linear, 1)]_AnimationMode("Animation Mode",Float) = 0
        _AnimationSpeed("Animation Speed", Float) = 1.0
        [HeaderEx(Animation)]
        [ToggleUI]_QuakeWater("Quake-style Distortion", Float) = 0

        [HeaderEx(System)]
        [Space]
        [Toggle(_LIGHTMAPSPECULAR)]_LightmapSpecular("Lightmap Specular", Range(0, 1)) = 1
        _LightmapSpecularMaxSmoothness("Lightmap Specular Max Smoothness", Range(0, 1)) = 1
        _ExposureOcclusion("Lightmap Occlusion Sensitivity", Range(0, 1)) = 0.2
        [Space]
        [KeywordEnum(None, SH, RNM, MonoSH)] _Bakery ("Bakery Mode", Int) = 0
        [HideInInspector]_RNM0("RNM0", 2D) = "black" {}
        [HideInInspector]_RNM1("RNM1", 2D) = "black" {}
        [HideInInspector]_RNM2("RNM2", 2D) = "black" {}
        [Toggle(_LTCGI)] _LTCGI ("LTCGI", Int) = 0
        [Toggle(_VRCLV)] _VRCLV ("VRC Light Volumes", Int) = 0
        [IfDef(_VRCLV)] _VRCLVSurfaceBias("Light Volume Surface Bias", Range(0, 0.5)) = 0.05
        [Space]

        [HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("__src", Float) = 1
        [HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("__dst", Float) = 0
        [HideInInspector][Enum(Off,0,On,1)]_ZWrite ("__zw", Float) = 1
        [HideInInspector]_AtoCmode("Cutout Transparency", Float) = 0

        [NonModifiableTextureData][HideInInspector] _DFG("DFG", 2D) = "white" {}
    }

    CustomEditor "Silent.FilamentedExtras.Unity.FilamentedExtrasInspector"

    CGINCLUDE
        #pragma shader_feature_local _ANIMATED

    	// First, setup what Filamented does.
    	// Filamented's behaviour is decided by the shading model and what material properties are defined.
    	// These are listed in FilamentMaterialInputs.
    	// You can set up and use anything in the initMaterials function.

    	// SHADING_MODEL_SPECULAR_GLOSSINESS
    	// If this is not defined, the material will default to metallic/roughness workflow.

        #define SKIP_UNITY_STANDARD_INPUT_DEFINES
        // If this is not defined, Unity Standard textures like _MainTex and _BumpMap
        // will be automatically defined.

    	#define MATERIAL_HAS_NORMAL
    	// If this is not defined, normal maps won't be enabled.

    	#define MATERIAL_HAS_AMBIENT_OCCLUSION
    	// If this is not defined, occlusion won't be taken into account

    	#define MATERIAL_HAS_EMISSIVE
    	// If this is not defined, emission won't be taken into account

    	// MATERIAL_HAS_ANISOTROPY
    	// If this is set, the material will support anisotropy.

    	// MATERIAL_HAS_CLEAR_COAT
    	// If this is set, the material will support clear coat.

        #define HAS_ATTRIBUTE_COLOR
        // If this is not defined, vertex colour will not be available.

        #define USE_DFG_LUT
        // Whether to use the lookup texture for specular reflection calculation.
        // Requires a shader property _DFG to be present and filled.
    ENDCG

    CGINCLUDE
    #ifndef UNITY_PASS_SHADOWCASTER

    // Include common files. These will include the other files as needed.
    #include "Packages/s-ilent.filamented/Filamented/UnityLightingCommon.cginc"
    #include "Packages/s-ilent.filamented/Filamented/UnityStandardInput.cginc"
    #include "Packages/s-ilent.filamented/Filamented/UnityStandardConfig.cginc"
    #include "Packages/s-ilent.filamented/Filamented/UnityStandardCore.cginc"

    uniform half4 _Color;
	uniform half _BumpScale;
	uniform half _MetallicScale;
	uniform half _OcclusionScale;
	uniform half _SmoothnessScale;
	uniform half _Emission;
	uniform half3 _EmissionColor;
    uniform half _VertexColourScale;

    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); half4 _MainTex_TexelSize;
    TEXTURE2D(_MOESMap); SAMPLER(sampler_MOESMap); half4 _MOESMap_TexelSize;
    TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap); half4 _BumpMap_TexelSize;

    half4 _MainTex_ST;

    #if defined(_ANIMATED)
    TEXTURE2D_ARRAY(_AnimationMainTex); SAMPLER(sampler_AnimationMainTex); half4 _AnimationMainTex_TexelSize;
    TEXTURE2D_ARRAY(_AnimationMOESMap); SAMPLER(sampler_AnimationMOESMap); half4 _AnimationMOESMap_TexelSize;
    TEXTURE2D_ARRAY(_AnimationBumpMap); SAMPLER(sampler_AnimationBumpMap); half4 _AnimationBumpMap_TexelSize;
    uniform fixed _AnimationMode;
    uniform float _AnimationSpeed;
    #endif

    uniform fixed _QuakeWater;

	// Vertex functions are called from UnityStandardCore.
	// You can alter values here, or copy the function in and modify it.
	VertexOutputForwardBase vertBase (VertexInput v) { return vertForwardBase(v); }
	VertexOutputForwardAdd vertAdd (VertexInput v) { return vertForwardAdd(v); }

    // Returns pixel sharpened to nearest pixel boundary.
    // texSize is Unity _Texture_TexelSize; zw is w/h, xy is 1/wh
    float2 sharpSample2( float4 texSize , float2 coord )
    {
        float2 boxSize = clamp(fwidth(coord) * texSize.zw, 1e-5, 1.0);
        coord = coord * texSize.zw - 0.5 * boxSize;
        float2 txOffset = smoothstep(1.0 - boxSize, 1.0, frac(coord));
        return (floor(coord) + 0.5 + txOffset) * texSize.xy;
    }

    float4 SampleTexture2DPixelFiltering(TEXTURE2D_PARAM(tex, smp), float2 coord, float4 texSize)
    {
        float2 boxSize = clamp(fwidth(coord) * texSize.zw, 1e-5, 1);
        coord = coord * texSize.zw - 0.5 * boxSize;
        float2 txOffset = smoothstep(1 - boxSize, 1, frac(coord));
        coord = (floor(coord) + 0.5 + txOffset) * texSize.xy;

        return SAMPLE_TEXTURE2D_GRAD(tex, smp, coord, ddx(coord), ddy(coord));
    }

    float4 SampleTexture2DArrayPixelFiltering(TEXTURE2D_ARRAY_PARAM(tex, smp), float2 coord, float4 texSize, float index)
    {
        float2 boxSize = clamp(fwidth(coord) * texSize.zw, 1e-5, 1);
        coord = coord * texSize.zw - 0.5 * boxSize;
        float2 txOffset = smoothstep(1 - boxSize, 1, frac(coord));
        coord = (floor(coord) + 0.5 + txOffset) * texSize.xy;

        return SAMPLE_TEXTURE2D_ARRAY_GRAD(tex, smp, coord, index, ddx(coord), ddy(coord));
    }

	// The material function itself!  You can alter the code below to add extra properties.
inline MaterialInputs MyMaterialSetup (inout float4 i_tex, float3 i_eyeVec, half3 i_viewDirForParallax, float4 tangentToWorld[3], float3 i_posWorld, float4 i_color)
{
    i_tex.xy = i_tex * _MainTex_ST.xy + _MainTex_ST.zw;
    // Animation stuff first.
    if (_QuakeWater)
    {
        i_tex.xy += float2(sin(_Time.y + i_tex.y * UNITY_PI),cos(_Time.y + i_tex.x * UNITY_PI)) * 0.1;
    }

    // Sample with derivatives to avoid artifacts.
    half4 baseColor = SampleTexture2DPixelFiltering(TEXTURE2D_ARGS(_MainTex, sampler_MainTex), i_tex.xy, _MainTex_TexelSize);
    half4 packedMap = SampleTexture2DPixelFiltering(TEXTURE2D_ARGS(_MOESMap, sampler_MOESMap), i_tex.xy, _MOESMap_TexelSize);
    half3 normalTangent = UnpackScaleNormal(SampleTexture2DPixelFiltering(TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), i_tex.xy, _BumpMap_TexelSize), _BumpScale);

    #if defined(_ANIMATED)
    uint width, height, elements;
    _AnimationMainTex.GetDimensions(width, height, elements);
    float tex_index = 0;

    switch (_AnimationMode) {
        case 0:
            float t = _Time.y * _AnimationSpeed;
            float phase = floor(t); // separate the integer part
            t = frac(t); // fractional part of time, in [0, 1)
            t = phase % 2 < 1 ? t : 1 - t; // reverse time every other cycle
            tex_index = t * (elements - 1);
            break;
        case 1:
            tex_index = floor(frac(_Time.y * _AnimationSpeed) * elements);
            break;
    }

    baseColor = SampleTexture2DArrayPixelFiltering(TEXTURE2D_ARRAY_ARGS(_AnimationMainTex, sampler_AnimationMainTex), i_tex.xy, _AnimationMainTex_TexelSize, tex_index );
    #endif

     // Vertex colour tint
    baseColor.rgb = lerp(baseColor.rgb, baseColor.rgb * i_color.rgb, _VertexColourScale);

    half metallic = packedMap.x * _MetallicScale;
    half occlusion = lerp(1, packedMap.y, _OcclusionScale);
    half emissionMask = packedMap.z;
    half smoothness = packedMap.w * _SmoothnessScale;

    MaterialInputs material = (MaterialInputs)0;
    initMaterial(material);
    material.baseColor = baseColor * _Color;
    material.metallic = metallic;
    material.roughness = computeRoughnessFromGlossiness(smoothness);
    material.normal = normalTangent;
    material.emissive.rgb = baseColor.rgb * emissionMask * _Emission * _EmissionColor;
    material.emissive.a = 1.0;
    material.ambientOcclusion = occlusion;
    return material;
}

half4 fragForwardBaseTemplate (VertexOutputForwardBase i)
{
    UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    ShadingParams shading = (ShadingParams)0;
    // Initialize shading with expected parameters
    computeShadingParamsForwardBase(shading, i);

    UNITY_LIGHT_ATTENUATION(atten, i, shading.position);

    #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
    GetBakedAttenuation(atten, i.ambientOrLightmapUV.xy, shading.position);
    #endif

    // Your material setup goes here.
    MaterialInputs material =
    MyMaterialSetup(i.tex, i.eyeVec.xyz, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i), i.color);

    prepareMaterial(shading, material);

#if (defined(_NORMALMAP) && defined(NORMALMAP_SHADOW))
    float noise = noiseR2(i.pos.xy);
    float nmShade = NormalTangentShadow (i.tex, i.lightDirTS, noise);
    shading.attenuation = min(shading.attenuation, max(1-nmShade, 0));
#endif

    float4 c = evaluateMaterial (shading, material);

    UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
    UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
    return c;
}

half4 fragForwardAddTemplate (VertexOutputForwardAdd i)
{
    UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    ShadingParams shading = (ShadingParams)0;
    // Initialize shading with expected parameters
    computeShadingParamsForwardAdd(shading, i);

    UNITY_LIGHT_ATTENUATION(atten, i, shading.position);

    // Your material setup goes here.
    MaterialInputs material =
    MyMaterialSetup(i.tex, i.eyeVec.xyz, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i), i.color);

    prepareMaterial(shading, material);

#if (defined(_NORMALMAP) && defined(NORMALMAP_SHADOW))
    float noise = noiseR2(i.pos.xy);
    float nmShade = NormalTangentShadow (i.tex, i.lightDirTS, noise);
    shading.attenuation = min(shading.attenuation, max(1-nmShade, 0));
#endif

    float4 c = evaluateMaterial (shading, material);

    UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
    UNITY_APPLY_FOG_COLOR(_unity_fogCoord, c.rgb, half4(0,0,0,0)); // fog towards black in additive pass
    return c;
}

half4 fragBase (VertexOutputForwardBase i) : SV_Target { return fragForwardBaseTemplate(i); }
half4 fragAdd (VertexOutputForwardAdd i) : SV_Target { return fragForwardAddTemplate(i); }
    #endif

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" "LTCGI" = "_LTCGI" }
        LOD 300

        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Cull [_CullMode]
            AlphaToMask [_AtoCmode]

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma target 4.0

            // -------------------------------------

            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature_local _LIGHTMAPSPECULAR

            #pragma shader_feature_local _ _BAKERY_RNM _BAKERY_SH _BAKERY_MONOSH
            #pragma shader_feature_local _LTCGI
            #pragma shader_feature_local _VRCLV
            #pragma shader_feature_local _LIGHTMAPSPECULAR

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertBase
            #pragma fragment fragBase

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest Equal
            Cull [_CullMode]
            AlphaToMask [_AtoCmode]

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------


            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertAdd
            #pragma fragment fragAdd

            ENDCG
        }

        // ------------------------------------------------------------------
        //  Shadow rendering pass
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual
            Cull [_CullMode]

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------

            #ifndef UNITY_PASS_SHADOWCASTER
            #define UNITY_PASS_SHADOWCASTER
            #endif

            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "Packages/s-ilent.filamented/Filamented/UnityStandardShadow.cginc"

            ENDCG
        }

    }

    FallBack "VertexLit"
}

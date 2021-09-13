#ifndef LMDINPUT_INCLUDED
#define LMDINPUT_INCLUDED

#include "LMDCommon.cginc"
#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"
#include "LMDUnityPBSLighting.cginc" // TBD: remove
#include "UnityStandardUtils.cginc"

//---------------------------------------
// Directional lightmaps & Parallax require tangent space too
#if (_NORMALMAP || DIRLIGHTMAP_COMBINED || _PARALLAXMAP)
    #define _TANGENT_TO_WORLD 1
#endif

#if (_DETAIL_MULX2 || _DETAIL_MUL || _DETAIL_ADD || _DETAIL_LERP)
    #define _DETAIL 1
#endif

//---------------------------------------
ColorNumber4       _Color;

#ifdef USE_COMBINE_PARAMS
ColorNumber4       _SurfaceColors[10];
#else
ColorNumber4       _SurfaceColor;
#endif
ColorNumber        _Cutoff;

sampler2D   _MainTex;
ColorNumber4      _MainTex_ST;

//sampler2D   _DetailAlbedoMap;
//float4      _DetailAlbedoMap_ST;

sampler2D   		_BumpMap;
VectorNumber        _BumpScale;

ColorNumber   _LightIntensity;
ColorNumber	 _LightLerpFactor;

ColorNumber _Occlusion;

//sampler2D   _DetailMask;
//sampler2D   _DetailNormalMap;
//half        _DetailNormalMapScale;

//sampler2D   _SpecGlossMap;
//sampler2D   _MetallicGlossMap;
//half        _Metallic;
//half        _Glossiness;
//half        _GlossMapScale;

//sampler2D   _OcclusionMap;
//half        _OcclusionStrength;

//sampler2D   _ParallaxMap;
//half        _Parallax;
//half        _UVSec;

//half4       _EmissionColor;
//sampler2D   _EmissionMap;

sampler2D _TattooTex;
ColorNumber _TattooToggle;

//-------------------------------------------------------------------------------------
// Input functions

struct VertexInput
{
    VectorNumber4 vertex   : POSITION;
    VectorNumber3 normal    : NORMAL;
    VectorNumber2 uv0      : TEXCOORD0;
    VectorNumber2 uv1      : TEXCOORD1;
#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
    VectorNumber2 uv2      : TEXCOORD2;
#endif
#ifdef _TANGENT_TO_WORLD
    VectorNumber4 tangent   : TANGENT;
#endif

#if defined(USE_COMBINE_PARAMS) ||  defined(USE_ANITREE_ON)
	VectorNumber4 color		: COLOR;
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

VectorNumber4 TexCoords(VertexInput v)
{
    VectorNumber4 texcoord;
    texcoord.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0
    //texcoord.zw = TRANSFORM_TEX(((_UVSec == 0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
    return texcoord;
}

/*half DetailMask(float2 uv)
{
    return tex2D (_DetailMask, uv).a;
}*/

VectorNumber3 Albedo(VectorNumber4 texcoords)
{
    VectorNumber3 albedo = _Color.rgb * tex2D (_MainTex, texcoords.xy).rgb;
    return albedo;
}

ColorNumber Alpha(ColorNumber2 uv)
{
#if defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A)
    return _Color.a;
#else
    return tex2D(_MainTex, uv).a * _Color.a;
#endif
}

/*half Occlusion(float2 uv)
{
#if (SHADER_TARGET < 30)
    // SM20: instruction count limitation
    // SM20: simpler occlusion
    return tex2D(_OcclusionMap, uv).g;
#else
    half occ = tex2D(_OcclusionMap, uv).g;
    return LerpOneTo (occ, _OcclusionStrength);
#endif
}*/

ColorNumber4 SpecularGloss(VectorNumber2 uv)
{
    ColorNumber4 sg = ColorNumber4(0,0,0,1);

    /*sg.rgb = _SpecColor.rgb;
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        sg.a = tex2D(_MainTex, uv).a * _GlossMapScale;
    #else
        sg.a = _Glossiness;
    #endif*/

    return sg;
}

/*half2 MetallicGloss(float2 uv)
{
    half2 mg;

#ifdef _METALLICGLOSSMAP
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        mg.r = tex2D(_MetallicGlossMap, uv).r;
        mg.g = tex2D(_MainTex, uv).a;
    #else
        mg = tex2D(_MetallicGlossMap, uv).ra;
    #endif
    mg.g *= _GlossMapScale;
#else
    mg.r = _Metallic;
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        mg.g = tex2D(_MainTex, uv).a * _GlossMapScale;
    #else
        mg.g = _Glossiness;
    #endif
#endif
    return mg;
}

half2 MetallicRough(float2 uv)
{
    half2 mg;
#ifdef _METALLICGLOSSMAP
    mg.r = tex2D(_MetallicGlossMap, uv).r;
#else
    mg.r = _Metallic;
#endif

#ifdef _SPECGLOSSMAP
    mg.g = 1.0f - tex2D(_SpecGlossMap, uv).r;
#else
    mg.g = 1.0f - _Glossiness;
#endif
    return mg;
}

half3 Emission(float2 uv)
{
#ifndef _EMISSION
    return 0;
#else
    return tex2D(_EmissionMap, uv).rgb * _EmissionColor.rgb;
#endif
}*/

#ifdef _NORMALMAP
VectorNumber3 NormalInTangentSpace(VectorNumber4 texcoords)
{
    VectorNumber3 normalTangent = UnpackScaleNormal(tex2D (_BumpMap, texcoords.xy), _BumpScale);

#if _DETAIL && defined(UNITY_ENABLE_DETAIL_NORMALMAP)
    VectorNumber mask = DetailMask(texcoords.xy);
    VectorNumber3 detailNormalTangent = UnpackScaleNormal(tex2D (_DetailNormalMap, texcoords.zw), _DetailNormalMapScale);
    #if _DETAIL_LERP
        normalTangent = lerp(
            normalTangent,
            detailNormalTangent,
            mask);
    #else
        normalTangent = lerp(
            normalTangent,
            BlendNormals(normalTangent, detailNormalTangent),
            mask);
    #endif
#endif

    return normalTangent;
}
#endif

/*float4 Parallax (float4 texcoords, half3 viewDir)
{
#if !defined(_PARALLAXMAP) || (SHADER_TARGET < 30)
    // Disable parallax on pre-SM3.0 shader target models
    return texcoords;
#else
    half h = tex2D (_ParallaxMap, texcoords.xy).g;
    float2 offset = ParallaxOffset1Step (h, _Parallax, viewDir);
    return float4(texcoords.xy + offset, texcoords.zw + offset);
#endif

}*/

#endif // UNITY_STANDARD_INPUT_INCLUDED
#ifndef P5PBR_INCLUDED
#define P5PBR_INCLUDED

//#include "UnityStandardCore.cginc"

#include "P5UnityStandardUtils.cginc"
#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityInstancing.cginc"
#include "UnityStandardConfig.cginc"
//#include "UnityStandardInput.cginc"
#include "P5Input.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityGBuffer.cginc"
#include "UnityStandardBRDF.cginc"

#include "AutoLight.cginc"

uniform sampler2D _MappingTex;
VectorNumber4 _MappingTex_ST;

uniform ColorNumber3 _EnvShadowColor;
#if _ANISOENABLE_ON
	uniform sampler2D _AnisoTex;
#endif
//uniform fixed4 _LightDir;

//float _DynamicShadowSize;
//float4x4 _DynamicShadowMatrix;
//float4 _DynamicShadowParam;
//sampler2D _DynamicShadowTexture;
//float3 _LightColor;

#if NEED_ENV_ON
	#ifdef REALTIME_REFLECTION_ON
		sampler2D _ReflectionTex;
		ColorNumber _ReflectionFactor;
		VectorNumber _TextureWidth = 256;
		VectorNumber _TextureHeight = 256;
	#else
		uniform samplerCUBE _EnvCubeMap;
	#endif
#endif

VectorNumber4 _BumpMap_ST;

#ifdef USE_FADE_TEX_ON
	sampler2D _FadeTex;
	VectorNumber _CurFadeTime;
	VectorNumber _fadeUVFactor;
	
	#ifdef USE_FADE_TEX_ADD_ON
	//融合过程中的叠加
	ColorNumber3 _fadeAddColor;
	VectorNumber  _fadeAddTime;
	#endif

/*#ifdef USE_FADE_TO_BLEND_ON
	fixed _fadeBlendStart = 0.1;
	fixed _fadeBlendEnd = 0.3;
#endif*/
	
	ColorNumber3 CalFadedAlbedoColor(ColorNumber3 oriAlbedo,VectorNumber2 uv)
	{
		ColorNumber3 fadeColor = tex2D(_FadeTex, uv * _MainTex_ST.xy + _MainTex_ST.zw).rgb;
		ColorNumber fadeA = tex2D(_FadeTex,uv * _fadeUVFactor).a;
		
		ColorNumber a = step(fadeA,_CurFadeTime);
		
	#ifdef USE_FADE_TO_BLEND_ON
		//fixed blendFactor = saturate((_CurFadeTime - _fadeBlendStart) / (_fadeBlendEnd - _fadeBlendStart));
		oriAlbedo.rgb = lerp(oriAlbedo.rgb,fadeColor.rgb,_CurFadeTime);
	#endif
		
	#ifdef USE_FADE_TEX_ADD_ON
		ColorNumber fadeFactor = saturate((_CurFadeTime - fadeA) / _fadeAddTime);
		fadeColor.rgb = lerp(_fadeAddColor.rgb,fadeColor.rgb,fadeFactor);
		fadeColor.rgb = lerp(oriAlbedo.rgb,fadeColor.rgb,fadeFactor);
	#endif

	
	return oriAlbedo.rgb * (1 - a) + fadeColor.rgb * a;
	
	}
	
	#ifdef _NORMALMAP
	
	sampler2D _FadeNormalTex;
	
	ColorNumber4 CalFadedNormal(ColorNumber4 oriNormal,VectorNumber2 uv)
	{
		ColorNumber4 fadeNormal = tex2D(_FadeNormalTex, uv * _BumpMap_ST.xy + _BumpMap_ST.zw);
		ColorNumber fadeA = tex2D(_FadeTex,uv * _fadeUVFactor).a;
		
		ColorNumber a = step(fadeA,_CurFadeTime);
		
		#ifdef USE_FADE_TO_BLEND_ON
		//fixed blendFactor = saturate((_CurFadeTime - _fadeBlendStart) / (_fadeBlendEnd - _fadeBlendStart));
		oriNormal = lerp(oriNormal,fadeNormal,_CurFadeTime);
		#endif
		
		return oriNormal * (1 - a) + fadeNormal * a;
	}
	
	#endif
	
	
#endif

#if defined (NEED_ENV_ON) && defined (REALTIME_REFLECTION_ON) && defined(BLUR_ON)
ColorNumber4 GetBlurColor( VectorNumber2 uv ,int lod)
{
	int _BlurRadius = 1;
	VectorNumber xSpace = 1.0/_TextureWidth; 
	VectorNumber ySpace = 1.0/_TextureHeight;
	int count = _BlurRadius * 2; 
	count *= count;

	//将以自己为中心，周围半径的所有颜色相加，然后除以总数，求得平均值
	ColorNumber4 colorTmp = ColorNumber4(0,0,0,0);
	for( int x = -_BlurRadius ; x <= _BlurRadius ; ++x )
	{
		for( int y = -_BlurRadius ; y <= _BlurRadius ; ++y )
		{
			ColorNumber4 color = tex2Dlod(_ReflectionTex, fixed4(uv + fixed2(x * xSpace,y * ySpace),lod,lod));
			colorTmp += color;
		}
	}
	return colorTmp/count;
}
#endif

struct VertexOutputForwardBaseEx
{
	UNITY_POSITION(pos);
	VectorNumber4 tex                          : TEXCOORD0;
	VectorNumber3 eyeVec                        : TEXCOORD1;
	VectorNumber4 tangentToWorldAndPackedData[3]    : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
	VectorNumber4 ambientOrLightmapUV           : TEXCOORD5;    // SH or Lightmap UV
	UNITY_SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)

	//#ifdef REALTIME_REFLECTION_ON
	VectorNumber4 screenPos                 : TEXCOORD8;
	//#endif
	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
	#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
	VectorNumber3 posWorld                  : TEXCOORD9;
	#endif

	/*UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO*/
};

//struct VertexOutputForwardBaseSkinFirstPass
//{
//	UNITY_POSITION(pos);
//	VectorNumber4 tex                          : TEXCOORD0;
//	VectorNumber4 tangentToWorldAndPackedData[3]    : TEXCOORD1;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
//	UNITY_FOG_COORDS(4)
//	
//	VectorNumber4 screenPos                 : TEXCOORD5;
//
//	#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
//	VectorNumber3 posWorld                  : TEXCOORD6;
//	#endif
//
//	UNITY_VERTEX_INPUT_INSTANCE_ID
//	UNITY_VERTEX_OUTPUT_STEREO
//};

//struct VertexOutputForwardBaseAdd
//{
//	UNITY_POSITION(pos);
//	VectorNumber4 tex                          : TEXCOORD0;
//	VectorNumber3 eyeVec                        : TEXCOORD1;
//	VectorNumber4 tangentToWorldAndPackedData[3]    : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
//	//half4 ambientOrLightmapUV           : TEXCOORD5;    // SH or Lightmap UV
//	UNITY_SHADOW_COORDS(5)
//	//UNITY_FOG_COORDS(6)
//
//	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
//	#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
//	VectorNumber3 posWorld                 : TEXCOORD6;
//	#endif
//
//	UNITY_VERTEX_INPUT_INSTANCE_ID
//	UNITY_VERTEX_OUTPUT_STEREO
//};

#define INV_PI 0.318309886f
#define PI 3.141592653f

ColorNumber sg(ColorNumber t, ColorNumber a)
{
	// return pow(a, t);
	ColorNumber k = t * 1.442695f + 1.089235f;
	return exp2(k * a - k);
}

ColorNumber3 f_schlick(ColorNumber3 f0, ColorNumber vDotH)
{
	return f0 + (1 - f0) * sg(5, 1 - vDotH);
}

ColorNumber d_ggx(ColorNumber roughness, ColorNumber nDotH)
{
	ColorNumber a = roughness * roughness;
	ColorNumber a2 = a * a;
	ColorNumber d = (nDotH * a2 - nDotH) * nDotH + 1;
	//return min(10000, a2 / (d * d + 0.00001) * INV_PI); 
	return min(10000, a2 / (d * d + 0.00001)); 
}

ColorNumber geometric(ColorNumber nDotV, ColorNumber nDotL, ColorNumber roughness)
{
	//fixed k = roughness * roughness;
	ColorNumber k = 0.5 + roughness * 0.5;
	k *= k;
	ColorNumber l = nDotL * (1.0 - k) + k;
	ColorNumber v = nDotV * (1.0 - k) + k;
	return 0.25 / (l * v + 0.00001);
}

ColorNumber3 envir_brdf(ColorNumber3 specularColor, ColorNumber roughness, ColorNumber nDotV)
{
	const ColorNumber4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const ColorNumber4 c1 = { 1, 0.0425, 1.04, -0.04 };
	ColorNumber4 r = roughness * c0 + c1;
	ColorNumber a004 = min(r.x * r.x, exp2( -9.28 * nDotV)) * r.x + r.y;
	ColorNumber2 AB = fixed2(-1.04, 1.04) * a004 + r.zw;
	return specularColor * AB.x + AB.y;// * 0.35;
}

ColorNumber3 envir_brdf_nonmetal(ColorNumber roughness, ColorNumber nDotV)
{
	const ColorNumber2 c0 = { -1, -0.0275 };
	const ColorNumber2 c1 = { 1, 0.0425 };
	ColorNumber2 r = roughness * c0 + c1;
	return min( r.x * r.x, exp2( -9.28 * nDotV ) ) * r.x + r.y;
}

//pbr shading
inline ColorNumber3 PbrShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,ColorNumber3 lightColor,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,VectorNumber3 lightDir,ColorNumber diffuseAlpha = 1.0)
{
	VectorNumber3 halfDir = normalize(lightDir + viewDir);
	
	ColorNumber3 diffuse = 0;
	ColorNumber3 specular = 0;
	
	VectorNumber nDotH = saturate(dot(normalWorld, halfDir));
	VectorNumber vDotH = saturate(dot(viewDir, halfDir));
	VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
	
	diffuse += albedo * (1 - metallic) * (nDotL * lightColor.rgb) * diffuseAlpha;
	
	ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
	ColorNumber3 F = f_schlick(base, vDotH);
	ColorNumber D = d_ggx(roughness, nDotH);
	ColorNumber G = geometric(nDotV, nDotL, roughness);
	specular += D * F * G * (nDotL * lightColor.rgb);
	
	return diffuse + specular;
}


//pbr only speacal
inline ColorNumber3 PbrShadingOnlySpecular(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,ColorNumber3 lightColor,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,VectorNumber3 lightDir)
{
	VectorNumber3 halfDir = normalize(lightDir + viewDir);
	
	ColorNumber3 specular = 0;
	
	VectorNumber nDotH = saturate(dot(normalWorld, halfDir));
	VectorNumber vDotH = saturate(dot(viewDir, halfDir));
	VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
	
	ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
	ColorNumber3 F = f_schlick(base, vDotH);
	ColorNumber D = d_ggx(roughness, nDotH);
	ColorNumber G = geometric(nDotV, nDotL, roughness);
	specular += D * F * G * (nDotL * lightColor.rgb);
	
	return specular;
}

//diffuse shading
inline ColorNumber3 DiffuseShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber3 lightColor,
	VectorNumber3 normalWorld,VectorNumber3 lightDir,ColorNumber diffuseAlpha = 1.0)
{
	ColorNumber3 diffuse = 0;
	
	VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
	
	diffuse += albedo * (1 - metallic) * (nDotL * lightColor.rgb) * diffuseAlpha;
	
	return diffuse;
}

//point light atten
inline ColorNumber CalPointLightAtten(VectorNumber distance,VectorNumber range,VectorNumber3 posWorld)
{
	//leanear
	return saturate((range - distance) / range);
}

// counterpart for NormalizePerPixelNormal
// skips normalization per-vertex and expects normalization to happen per-pixel
VectorNumber3 NormalizePerVertexNormal (VectorNumber3 n) // takes float to avoid overflow
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return normalize(n);
    #else
        return n; // will normalize per-pixel instead
    #endif
}

VectorNumber3 NormalizePerPixelNormal (VectorNumber3 n)
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return n;
    #else
        return normalize(n);
    #endif
}

//-------------------------------------------------------------------------------------
UnityLight MainLight ()
{
    UnityLight l;

    l.color = _LightColor0.rgb;
    l.dir = _WorldSpaceLightPos0.xyz;
    return l;
}

UnityLight AdditiveLight (VectorNumber3 lightDir, VectorNumber atten)
{
    UnityLight l;

    l.color = _LightColor0.rgb;
    l.dir = lightDir;
    #ifndef USING_DIRECTIONAL_LIGHT
        l.dir = NormalizePerPixelNormal(l.dir);
    #endif

    // shadow the light
    l.color *= atten;
    return l;
}

UnityLight DummyLight ()
{
    UnityLight l;
    l.color = 0;
    l.dir = VectorNumber3 (0,1,0);
    return l;
}

UnityIndirect ZeroIndirect ()
{
    UnityIndirect ind;
    ind.diffuse = 0;
    ind.specular = 0;
    return ind;
}

//-------------------------------------------------------------------------------------
// Common fragment setup

// deprecated
VectorNumber3 WorldNormal(VectorNumber4 tan2world[3])
{
    return normalize(tan2world[2].xyz);
}

// deprecated
#ifdef _TANGENT_TO_WORLD
    half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
    {
        half3 t = tan2world[0].xyz;
        half3 b = tan2world[1].xyz;
        half3 n = tan2world[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        n = NormalizePerPixelNormal(n);

        // ortho-normalize Tangent
        t = normalize (t - n * dot(t, n));

        // recalculate Binormal
        half3 newB = cross(n, t);
        b = newB * sign (dot (newB, b));
    #endif

        return half3x3(t, b, n);
    }
#else
    half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
    {
        return half3x3(0,0,0,0,0,0,0,0,0);
    }
#endif

half3 PerPixelWorldNormal(float4 i_tex, half4 tangentToWorld[3])
{
#ifdef _NORMALMAP
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        normal = NormalizePerPixelNormal(normal);

        // ortho-normalize Tangent
        tangent = normalize (tangent - normal * dot(tangent, normal));

        // recalculate Binormal
        half3 newB = cross(normal, tangent);
        binormal = newB * sign (dot (newB, binormal));
    #endif

    half3 normalTangent = NormalInTangentSpace(i_tex);
    half3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
#else
    half3 normalWorld = normalize(tangentToWorld[2].xyz);
#endif
	
    return normalWorld;
}

VectorNumber4 PerPixelWorldNormalAndAo(VectorNumber4 i_tex, VectorNumber4 tangentToWorld[3])
{
#ifdef _NORMALMAP
    VectorNumber3 tangent = normalize(tangentToWorld[0].xyz);
    VectorNumber3 binormal = normalize(tangentToWorld[1].xyz);
    VectorNumber3 normal = normalize(tangentToWorld[2].xyz);
	
	VectorNumber4 normalColor = tex2D(_BumpMap, i_tex * _BumpMap_ST.xy + _BumpMap_ST.zw);
	
#ifdef USE_FADE_TEX_ON
	normalColor = CalFadedNormal(normalColor,i_tex);
#endif
	
	normalColor.xy = normalColor.xy * 2 - 1;
	VectorNumber3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
	VectorNumber3 normalWorld = normalize(normal + normalOffset);
	return VectorNumber4(normalWorld,normalColor.z);
#else
    VectorNumber3 normalWorld = normalize(tangentToWorld[2].xyz);
	return VectorNumber4(normalWorld,1);
#endif
}

#ifdef _PARALLAXMAP
    #define IN_VIEWDIR4PARALLAX(i) NormalizePerPixelNormal(VectorNumber3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w))
    #define IN_VIEWDIR4PARALLAX_FWDADD(i) NormalizePerPixelNormal(i.viewDirForParallax.xyz)
#else
    #define IN_VIEWDIR4PARALLAX(i) VectorNumber3(0,0,0)
    #define IN_VIEWDIR4PARALLAX_FWDADD(i) VectorNumber3(0,0,0)
#endif

#if UNITY_REQUIRE_FRAG_WORLDPOS
    #if UNITY_PACK_WORLDPOS_WITH_TANGENT
        #define IN_WORLDPOS(i) VectorNumber3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w)
    #else
        #define IN_WORLDPOS(i) i.posWorld
    #endif
    #define IN_WORLDPOS_FWDADD(i) i.posWorld
#else
    #define IN_WORLDPOS(i) VectorNumber3(0,0,0)
    #define IN_WORLDPOS_FWDADD(i) VectorNumber3(0,0,0)
#endif

#define IN_LIGHTDIR_FWDADD(i) VectorNumber3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w)

#define FRAGMENT_SETUP(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i));

#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i));

struct FragmentCommonData
{
    ColorNumber3 diffColor, specColor;
    // Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
    // Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
    ColorNumber oneMinusReflectivity, smoothness;
    VectorNumber3 normalWorld, eyeVec;
    ColorNumber alpha;
	ColorNumber ao;
    VectorNumber3 posWorld;

#if UNITY_STANDARD_SIMPLE
    VectorNumber3 reflUVW;
#endif

#if UNITY_STANDARD_SIMPLE
    VectorNumber3 tangentSpaceNormal;
#endif
};

#ifndef UNITY_SETUP_BRDF_INPUT
    #define UNITY_SETUP_BRDF_INPUT SpecularSetup
#endif

inline FragmentCommonData SpecularSetup (VectorNumber4 i_tex)
{
    ColorNumber4 specGloss = SpecularGloss(i_tex.xy);
    ColorNumber3 specColor = specGloss.rgb;
    ColorNumber smoothness = specGloss.a;

    ColorNumber oneMinusReflectivity;
    ColorNumber3 diffColor = EnergyConservationBetweenDiffuseAndSpecular (Albedo(i_tex), specColor, /*out*/ oneMinusReflectivity);

    FragmentCommonData o = (FragmentCommonData)0;
    o.diffColor = diffColor;
    o.specColor = specColor;
    o.oneMinusReflectivity = oneMinusReflectivity;
    o.smoothness = smoothness;
    return o;
}

// parallax transformed texcoord is used to sample occlusion
inline FragmentCommonData FragmentSetup (inout VectorNumber4 i_tex, VectorNumber3 i_eyeVec, VectorNumber3 i_viewDirForParallax, VectorNumber4 tangentToWorld[3], VectorNumber3 i_posWorld)
{
    //i_tex = Parallax(i_tex, i_viewDirForParallax);

    ColorNumber alpha = Alpha(i_tex.xy);
    #if defined(_ALPHATEST_ON)
        clip (alpha - _Cutoff);
    #endif

    FragmentCommonData o = UNITY_SETUP_BRDF_INPUT (i_tex);
	VectorNumber4 normalWorldAndAo = PerPixelWorldNormalAndAo(i_tex, tangentToWorld);
    o.normalWorld = normalWorldAndAo.xyz;
	o.ao = normalWorldAndAo.w;
    o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
    o.posWorld = i_posWorld;

    // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
    o.diffColor = PreMultiplyAlpha (o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
    return o;
}

inline UnityGI FragmentGI (FragmentCommonData s, ColorNumber occlusion, VectorNumber4 i_ambientOrLightmapUV, ColorNumber atten, UnityLight light, bool reflections)
{
    UnityGIInput d;
    d.light = light;
    d.worldPos = s.posWorld;
    d.worldViewDir = -s.eyeVec;
    d.atten = atten;
    #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
        d.ambient = 0;
        d.lightmapUV = i_ambientOrLightmapUV;
    #else
        d.ambient = i_ambientOrLightmapUV.rgb;
        d.lightmapUV = 0;
    #endif

    d.probeHDR[0] = unity_SpecCube0_HDR;
    d.probeHDR[1] = unity_SpecCube1_HDR;
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
      d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
      d.boxMax[0] = unity_SpecCube0_BoxMax;
      d.probePosition[0] = unity_SpecCube0_ProbePosition;
      d.boxMax[1] = unity_SpecCube1_BoxMax;
      d.boxMin[1] = unity_SpecCube1_BoxMin;
      d.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif

    if(reflections)
    {
        Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.smoothness, -s.eyeVec, s.normalWorld, s.specColor);
        // Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
        #if UNITY_STANDARD_SIMPLE
            g.reflUVW = s.reflUVW;
        #endif

        return UnityGlobalIllumination (d, occlusion, s.normalWorld, g);
    }
    else
    {
        return UnityGlobalIllumination (d, occlusion, s.normalWorld);
    }
}

inline UnityGI FragmentGI (FragmentCommonData s, ColorNumber occlusion, VectorNumber4 i_ambientOrLightmapUV, ColorNumber atten, UnityLight light)
{
    return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, true);
}


//-------------------------------------------------------------------------------------
ColorNumber4 OutputForward (ColorNumber4 output, ColorNumber alphaFromSurface)
{
    #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
        output.a = alphaFromSurface;
    #else
        UNITY_OPAQUE_ALPHA(output.a);
    #endif
    return output;
}

inline ColorNumber4 VertexGIForward(VertexInput v, VectorNumber3 posWorld, VectorNumber3 normalWorld)
{
    VectorNumber4 ambientOrLightmapUV = 0;
    // Static lightmaps
    #ifdef LIGHTMAP_ON
        ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        ambientOrLightmapUV.zw = 0;
    // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
    #elif UNITY_SHOULD_SAMPLE_SH
        #ifdef VERTEXLIGHT_ON
            // Approximated illumination from non-important point lights
            ambientOrLightmapUV.rgb = Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, posWorld, normalWorld);
        #endif

        ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    return ambientOrLightmapUV;
}

inline UnityGI FragmentGI(
    VectorNumber3 posWorld,
    ColorNumber occlusion, VectorNumber4 i_ambientOrLightmapUV, ColorNumber atten, ColorNumber smoothness, VectorNumber3 normalWorld, VectorNumber3 eyeVec,
    UnityLight light,
    bool reflections)
{
    // we init only fields actually used
    FragmentCommonData s = (FragmentCommonData)0;
    s.smoothness = smoothness;
    s.normalWorld = normalWorld;
    s.eyeVec = eyeVec;
    s.posWorld = posWorld;
    return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, reflections);
}
inline UnityGI FragmentGI (
    VectorNumber3 posWorld,
    ColorNumber occlusion, VectorNumber4 i_ambientOrLightmapUV, ColorNumber atten, ColorNumber smoothness, VectorNumber4 normalWorld, VectorNumber4 eyeVec,
    UnityLight light)
{
    return FragmentGI (posWorld, occlusion, i_ambientOrLightmapUV, atten, smoothness, normalWorld, eyeVec, light, true);
}


#ifdef _USE_FORWARD_PLUS_RENDER_ON

/**

tiled base forward rendering 

forward + rendering

**/ 
struct DirectLight
{
	float3 dir;
	float3 color;
};

struct PointLight
{
	float4 positionWS;                          

	float4 positionVS;                         

	float3 color; 
	float  range;                            

	float  intensity;
	
	uint enable;
};

uint _mTileWidth;
VectorNumber4 _mTileWHinfo;
float2 _mWHRatio;

int _mDirectLightCount;
StructuredBuffer<DirectLight> _mDirectLights;

StructuredBuffer<PointLight> _mPointLights;

#ifdef _USE_COMPUTE_SHADER_ON
StructuredBuffer<uint4> _mPointLightHeadGrid;
StructuredBuffer<uint2> _mPointLightIndexList;
#else
StructuredBuffer<int2>  _mPointLightHeadGrid;
StructuredBuffer<int4> _mPointLightIndexList;
#endif

inline ColorNumber3 PbrDirectLightShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,DirectLight dirLight,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,ColorNumber diffuseAlpha = 1.0)
{
	VectorNumber3 lightDir = dirLight.dir;

	#ifdef _NON_USE_PBR_GLOSSY_ON
	return DiffuseShading(albedo, metallic, dirLight.color, normalWorld, lightDir,diffuseAlpha);
	#else
	return PbrShading(albedo, metallic, roughness, dirLight.color, 
		normalWorld, viewDir, nDotV, lightDir,diffuseAlpha) ;
	#endif
}

//inline ColorNumber3 AllDirectLightsShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,VectorNumber3 posWorld,
//	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,ColorNumber diffuseAlpha = 1.0)
//{
//	ColorNumber3 color = ColorNumber3(0,0,0);
//	
//	for(int i = 0;i < _mDirectLightCount;i++)
//	{
//		DirectLight dirLight = _mDirectLights[i];
//		color += PbrDirectLightShading(albedo,metallic,roughness,dirLight,posWorld,normalWorld,viewDir,nDotV,diffuseAlpha);
//	}
//	
//	return color;
//}

inline ColorNumber3 AllDirectLightsShadingDiffuse(ColorNumber3 albedo,ColorNumber metallic,VectorNumber3 normalWorld,ColorNumber diffuseAlpha = 1.0)
{
	ColorNumber3 color = ColorNumber3(0,0,0);
	
	for(int i = 0;i < _mDirectLightCount;i++)
	{
		DirectLight dirLight = _mDirectLights[i];
		VectorNumber3 lightDir = dirLight.dir;
		color += DiffuseShading(albedo, metallic, dirLight.color, normalWorld, lightDir,diffuseAlpha);
	}
	
	return color;
}

inline ColorNumber3 AllDirectLightsShadingOnlySpecular(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV)
{
	ColorNumber3 color = ColorNumber3(0,0,0);
	
	for(int i = 0;i < _mDirectLightCount;i++)
	{
		DirectLight dirLight = _mDirectLights[i];
		VectorNumber3 lightDir = dirLight.dir;
		color += PbrShadingOnlySpecular(albedo, metallic, roughness, dirLight.color, 
			normalWorld, viewDir, nDotV, lightDir);
	}
	
	return color;
}

//one point light shading
inline ColorNumber3 PbrPointLightShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,PointLight pointLight,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,ColorNumber diffuseAlpha = 1.0)
{
	VectorNumber3 lightDir = pointLight.positionWS.xyz - posWorld;
	
	ColorNumber atten = CalPointLightAtten(length(lightDir),pointLight.range, posWorld);
	
	lightDir = normalize(lightDir);
	
	#ifdef _NON_USE_PBR_GLOSSY_ON
	return DiffuseShading(albedo, metallic, pointLight.color * pointLight.intensity, 
		normalWorld, lightDir,diffuseAlpha) * atten;
	#else
	return PbrShading(albedo, metallic, roughness, pointLight.color * pointLight.intensity, 
		normalWorld, viewDir, nDotV, lightDir,diffuseAlpha) * atten;
	#endif
}

//all point lights shadding
inline ColorNumber3 AllPointLightsShading(VectorNumber2 screenPosXY,
	ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,ColorNumber diffuseAlpha = 1.0)
{
	uint2 gridIndexXY;
	
	ColorNumber3 color = ColorNumber3(0,0,0);
	
#ifdef _USE_COMPUTE_SHADER_ON
	gridIndexXY.x = floor(screenPosXY.x / _mTileWHinfo.z);
	gridIndexXY.y = floor(screenPosXY.y / _mTileWHinfo.w);
	uint gridIndex = gridIndexXY.y * _mTileWidth + gridIndexXY.x;
	
	uint2 offsetCount = _mPointLightHeadGrid[gridIndex + 1].xy;//tex2D(_mPointLightGrid_OPAQUE,lightUV).rg;
	
	for(uint k = 0;k < offsetCount.y;k++)
	{
		PointLight pointLight = _mPointLights[_mPointLightIndexList[offsetCount.x + k].x];
		
		//debug
		//float3 ldir = pointLight.positionWS.xyz - posWorld.xyz;
		
		//if((pointLight.range - length(ldir)) >= 0)
		//	return ColorNumber3(1,0,0);
		//else
		//	return ColorNumber3(0,1,0);
	
		//if((pointLight.range - length(ldir)) < 0)
		//	color += ColorNumber3(0.3,0,0);
		//else
		//	color += ColorNumber3(0,0.3,0);
		
		color += PbrPointLightShading(albedo,metallic,roughness,pointLight,posWorld,normalWorld,viewDir,nDotV,diffuseAlpha);
	}
#else
	gridIndexXY.x = floor(screenPosXY.x / _mTileWHinfo.x);
	gridIndexXY.y = floor(screenPosXY.y / _mTileWHinfo.y);
	
	uint gridIndex = gridIndexXY.y * _mTileWidth + gridIndexXY.x;
	
	int head = _mPointLightHeadGrid[gridIndex + 1].x;
	
	//if(any(head))
	//	return ColorNumber3(0,1,0);
	//else
	//	return ColorNumber3(1,0,0);

	while(any(head))
	{
		int2 linked = _mPointLightIndexList[head].xy;
		PointLight pointLight = _mPointLights[linked.x];
		
		//float3 ldir = pointLight.positionWS.xyz - posWorld.xyz;
		//if((pointLight.range - length(ldir)) < 0)
		//	color += ColorNumber3(0.3,0,0);
		//else
		//	color += ColorNumber3(0,0.3,0);
		
		color += PbrPointLightShading(albedo,metallic,roughness,pointLight,posWorld,normalWorld,viewDir,nDotV,diffuseAlpha);
		
		head = linked.y;
	}
	
	/*uint allFlag = _mlightBackFaceInfos[gridIndex];
	uint flag;
	for(int i = 0;i < 15;i++)
	{
		flag = allFlag & (1 << i);
		if(any(flag))
		{
			PointLight pointLight = _mPointLights[i];
		
			//float3 ldir = pointLight.positionWS.xyz - posWorld.xyz;
			//if((pointLight.range - length(ldir)) < 0)
			//	color += ColorNumber3(0.3,0,0);
			//else
			//	color += ColorNumber3(0,0.3,0);
		
			color += PbrPointLightShading(albedo,metallic,roughness,pointLight,posWorld,normalWorld,viewDir,nDotV);
		}
	}*/
#endif

	return color;
}

//all point lights shadding
inline ColorNumber3 AllPointLightsShadingDiffuse(VectorNumber2 screenPosXY,
	ColorNumber3 albedo,ColorNumber metallic,VectorNumber3 posWorld,VectorNumber3 normalWorld,ColorNumber diffuseAlpha = 1.0)
{
	uint2 gridIndexXY;
	
	ColorNumber3 color = ColorNumber3(0,0,0);
	
#ifdef _USE_COMPUTE_SHADER_ON
	gridIndexXY.x = floor(screenPosXY.x / _mTileWHinfo.z);
	gridIndexXY.y = floor(screenPosXY.y / _mTileWHinfo.w);
	uint gridIndex = gridIndexXY.y * _mTileWidth + gridIndexXY.x;
	
	uint2 offsetCount = _mPointLightHeadGrid[gridIndex + 1].xy;//tex2D(_mPointLightGrid_OPAQUE,lightUV).rg;
	
	for(uint k = 0;k < offsetCount.y;k++)
	{
		PointLight pointLight = _mPointLights[_mPointLightIndexList[offsetCount.x + k].x];
		
		VectorNumber3 lightDir = pointLight.positionWS.xyz - posWorld;
	
		ColorNumber atten = CalPointLightAtten(length(lightDir),pointLight.range, posWorld);
	
		lightDir = normalize(lightDir);
	
		color += DiffuseShading(albedo, metallic, pointLight.color * pointLight.intensity, 
			normalWorld, lightDir,diffuseAlpha) * atten;
	}
#else
	gridIndexXY.x = floor(screenPosXY.x / _mTileWHinfo.x);
	gridIndexXY.y = floor(screenPosXY.y / _mTileWHinfo.y);
	
	uint gridIndex = gridIndexXY.y * _mTileWidth + gridIndexXY.x;
	
	int head = _mPointLightHeadGrid[gridIndex + 1].x;

	while(any(head))
	{
		int2 linked = _mPointLightIndexList[head].xy;
		PointLight pointLight = _mPointLights[linked.x];
		
		VectorNumber3 lightDir = pointLight.positionWS.xyz - posWorld;
	
		ColorNumber atten = CalPointLightAtten(length(lightDir),pointLight.range, posWorld);
	
		lightDir = normalize(lightDir);
		
		color += DiffuseShading(albedo, metallic, pointLight.color * pointLight.intensity, 
			normalWorld, lightDir,diffuseAlpha) * atten;
		
		head = linked.y;
	}
#endif

	return color;
}

/*ColorNumber3 AllPointLightsShading(VectorNumber2 screenPosXY,
	ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV)
{
	ColorNumber3 color = ColorNumber3(0,0,0);
	
	for(uint k = 0;k < 10;k++)
	{
		PointLight pointLight = _mPointLights[k];
		
		
		//debug
		//float3 ldir = pointLight.positionWS.xyz - posWorld.xyz;
		
		//if((pointLight.range - length(ldir)) >= 0)
		//	return ColorNumber3(1,0,0);
		//else
		//	return ColorNumber3(0,1,0);
		
		//if((pointLight.range - length(ldir)) < 0)
		//	continue;
		
		//diffuse += albedo.rgb * (1 - metallic) * saturate(dot(nldir,normal)) * pointLight.color.rgb * pointLight.intensity * saturate((pointLight.range - length(ldir)) / pointLight.range);
		
		//color += PbrPointLightShading(albedo,metallic,roughness,pointLight,posWorld,normalWorld,viewDir,nDotV);
		
		color += pointLight.color;
	}
	
	return color;
}*/

#endif

#endif
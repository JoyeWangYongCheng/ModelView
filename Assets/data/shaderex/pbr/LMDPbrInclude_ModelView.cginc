// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef LMDPBR_INCLUDED
#define LMDPBR_INCLUDED

#if defined(TYPE_SCENE)
	#define LIGHTMAP_ON 1
	//#define LIGHTMAP_SHADOW_MIXING 1
#endif

#if defined(NON_USE_FOG_ON) && defined(FOG_LINEAR)
	#undef FOG_LINEAR
#endif

//#ifdef ST2_LAND
//test
//#define SHADOWS_SHADOWMASK
//#undef DYNAMICLIGHTMAP_ON
//#undef LIGHTMAP_ON
//#endif

//#undef UNITY_COLORSPACE_GAMMA

//#include "UnityStandardCore.cginc"

#include "LMDUnityStandardUtils.cginc"
#include "LMDUnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityInstancing.cginc"
#include "UnityStandardConfig.cginc"
//#include "UnityStandardInput.cginc"
#include "LMDInput.cginc"
#include "LMDUnityPBSLighting.cginc"

//#include "LMDUnityStandardUtils.cginc"
//#include "UnityStandardUtils.cginc"

#include "UnityGBuffer.cginc"
#include "UnityStandardBRDF.cginc"

#include "AutoLight.cginc"

uniform sampler2D _MappingTex;
VectorNumber4 _MappingTex_ST;

uniform sampler2D _AnisoTex;
VectorNumber4 _AnisoTex_ST;

uniform sampler2D _ThinFilmMask;
VectorNumber4 _ThinFilmMask_ST;

VectorNumber4 _Emission;
VectorNumber _EmissionFactor;

#ifdef USE_COMBINE_PARAMS
uniform ColorNumber3 _EnvShadowColors[10];
#else
uniform ColorNumber3 _EnvShadowColor;
#endif

uniform sampler2D _HQCharShadowmap, _HQCharShadowmapTransparent;
VectorNumber4 _HQCharCameraParams;
float4x4 _HQCharCameraVP;
VectorNumber _HQCharShadowmapSize;
VectorNumber _Bias;
#ifdef USE_ROLELIGHYINTENSITY_ON
float _RoleLightIntensity;
#endif
//uniform fixed4 _LightDir;

//float _DynamicShadowSize;
//float4x4 _DynamicShadowMatrix;
//float4 _DynamicShadowParam;
//sampler2D _DynamicShadowTexture;
//float3 _LightColor;

ColorNumber st2BlackFactor;

#ifdef USE_ANITREE_ON
half _ColorMultiplier;
//uniform half st2BlackFactor;
half4 _Fog;
half _Factor;
half _Amplitude;
half _Frequency;
half _Amplitude01; 
half _Frequency01;		
half4 _WindDir;			
#endif

#ifdef USE_THINFILMREFLECT_ON
Vector _IOR;
half  _FilmDepth;
VectorNumber4 _ThinFilmColor;
#endif

#ifdef USE_ANITREE_ON
half SimulateFog(half4 pos)
		{
#if defined(UNITY_REVERSED_Z)
	#if UNITY_REVERSED_Z == 1
			half z = max(((1.0 - (pos.z) / _ProjectionParams.y)*_ProjectionParams.z), 0);
	#else
			half z = max(-(pos.z), 0);
	#endif
#elif UNITY_UV_STARTS_AT_TOP
			half z = pos.z;
#else
			half z = pos.z;
#endif
			half fogFactor = exp2(-_Factor * z);
			fogFactor = clamp(fogFactor, 0.0, 1.0);
			return fogFactor;
		}
#endif

#ifdef USE_THINFILMREFLECT_ON

half thinFilmReflectance(fixed cosI, float lambda, float thickness, float IOR)
{
	float PI = 3.1415926;
	fixed sin2R = saturate((1 - pow(cosI, 2)) / pow(IOR, 2));
	fixed cosR = sqrt(1 - sin2R);
	float phi = 2.0*IOR*thickness*cosR / lambda + 0.5; //计算光程差
	fixed reflectionRatio = 1 - pow(cos(phi * PI*2.0)*0.5 + 0.5, 1.0);  //反射系数

	fixed  refRatio_min = pow((1 - IOR) / (1 + IOR), 2.0);

	reflectionRatio = refRatio_min + (1.0 - refRatio_min) * reflectionRatio;

	return reflectionRatio;
}
#endif





#ifdef USE_NRP_ON
	// normal should be normalized, w=1.0
	half3 LMDSHEvalLinearL0L1(half4 normal) {
		half3 x;
		fixed4 unity_SHAr = fixed4(-0.27, 1.1, -1.1, 2.1);
		fixed4 unity_SHAg = fixed4(-0.21, 1, -0.96, 1.5);
		fixed4 unity_SHAb = fixed4(-0.16, 0.97, -0.76, 1.1);

		// Linear (L1) + constant (L0) polynomial terms
		x.r = dot(unity_SHAr, normal);
		x.g = dot(unity_SHAg, normal);
		x.b = dot(unity_SHAb, normal);

		return x;
	}

	// normal should be normalized, w=1.0
	half3 LMDSHEvalLinearL2(half4 normal) {
		half3 x1, x2;
		fixed4 unity_SHBr = fixed4(-0.4, 0.67, 1, 0.54);
		fixed4 unity_SHBg = fixed4(-0.27, -0.54, 0.68, 0.42);
		fixed4 unity_SHBb = fixed4(-0.19, -0.44, 0.4, 0.35);
		fixed4 unity_SHC = fixed4(0.17, 0.13, 0.085, 1);
		// 4 of the quadratic (L2) polynomials
		half4 vB = normal.xyzz * normal.yzzx;
		x1.r = dot(unity_SHBr, vB);
		x1.g = dot(unity_SHBg, vB);
		x1.b = dot(unity_SHBb, vB);

		// Final (5th) quadratic (L2) polynomial
		half vC = normal.x * normal.x - normal.y * normal.y;
		x2 = unity_SHC.rgb * vC;

		return x1 + x2;
	}

	// normal should be normalized, w=1.0
	// output in active color space
	half3 LMDShadeSH9(half4 normal) {
		// Linear + constant polynomial terms
		half3 res = LMDSHEvalLinearL0L1(normal);

		// Quadratic polynomials
		res += LMDSHEvalLinearL2(normal);

		if (IsGammaSpace())
			res = LinearToGammaSpace(res);

		return res;
	}
#endif

#ifdef	USE_SELFSHADOW_ON
	float PCFForNoTrans(float2 xy, float sceneDepth, float bias)
	{
		float shadow = 0.0;
		float2 texelSize = float2(1 / _HQCharShadowmapSize, 1 / _HQCharShadowmapSize) * 1;
		float4 shadowData = 0;

		float2 sampelDisk[4] = { float2(0,0),float2(0,1),float2(0.7,-0.7),float2(-0.7,-0.7) };
		for (int i = 0; i < 4; ++i)
		{
			float2 sampeluv = sampelDisk[i] * texelSize + xy;
			shadowData = tex2D(_HQCharShadowmap, sampeluv);

		#if defined(UNITY_REVERSED_Z) && UNITY_REVERSED_Z == 1
			float depth = shadowData.x;
			float v = step(depth, sceneDepth + bias);
		#else
			float depth = shadowData.x * 2 - 1;
			float v = step(sceneDepth, depth + bias);
		#endif

			shadow += v;
		}
		return (shadow*0.25);
	}
#endif

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
		ColorNumber3 fadeColor = tex2D(_FadeTex, uv /** _MainTex_ST.xy + _MainTex_ST.zw*/).rgb * _Color.rgb;
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
		ColorNumber4 fadeNormal = tex2D(_FadeNormalTex, uv /** _BumpMap_ST.xy + _BumpMap_ST.zw*/);
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

#if (defined(NEED_ENV_ON) && defined(REALTIME_REFLECTION_ON)) || (defined(_USE_FORWARD_PLUS_RENDER_ON) && !defined(_FORCE_NO_USE_FORWARD_PLUS_RENDER_ON)) || (defined(_USE_SCREEN_SSS_ON))
#define NEED_SCREENPOS
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
	//VectorNumber4 screenPos                 : TEXCOORD8;
	//#endif
	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
	#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
	VectorNumber3 posWorld                  : TEXCOORD8;
		#ifdef NEED_SCREENPOS
	VectorNumber4 screenPos : TEXCOORD9;
		#endif
	#else
		#ifdef NEED_SCREENPOS
	VectorNumber4 screenPos : TEXCOORD8;
		#endif
	#endif

#ifdef USE_COMBINE_PARAMS
	VectorNumber fParamsIndex : TEXCOORD9;
#endif
#ifdef USE_ANITREE_ON
    VectorNumber treeFog : TEXCOORD10;
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

struct VertexOutputForwardBaseSkinFirstPass
{
	UNITY_POSITION(pos);
	VectorNumber4 tex                          : TEXCOORD0;
	VectorNumber4 tangentToWorldAndPackedData[3]    : TEXCOORD1;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
	UNITY_FOG_COORDS(4)
	
	#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
		VectorNumber3 posWorld : TEXCOORD5;
		#ifdef NEED_SCREENPOS
		VectorNumber4 screenPos : TEXCOORD6;
		#endif
	#else
		#ifdef NEED_SCREENPOS
		VectorNumber4 screenPos : TEXCOORD5;
		#endif
	#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

struct VertexOutputForwardBaseAdd
{
	UNITY_POSITION(pos);
	VectorNumber4 tex                          : TEXCOORD0;
	VectorNumber3 eyeVec                        : TEXCOORD1;
	VectorNumber4 tangentToWorldAndPackedData[3]    : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
	//half4 ambientOrLightmapUV           : TEXCOORD5;    // SH or Lightmap UV
	UNITY_SHADOW_COORDS(5)
	//UNITY_FOG_COORDS(6)

	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
	#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
	VectorNumber3 posWorld                 : TEXCOORD6;
	#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

#define INV_PI 0.318309886f
#define PI 3.141592653f

float sg(float t, float a)
{
	// return pow(a, t);
	float k = t * 1.442695f + 1.089235f;
	return exp2(k * a - k);
}

float3 f_schlick(float3 f0, float vDotH)
{
	return f0 + (1 - f0) * sg(5, 1 - vDotH);
}

float d_ggx(float roughness, float nDotH)
{
	float a = roughness * roughness;
	float a2 = a * a;
	float d = (nDotH * a2 - nDotH) * nDotH + 1;
	//return min(10000, a2 / (d * d + 0.00001) * INV_PI); 
	return min(10000, a2 / (d * d + 0.00001)); 
}

float geometric(float nDotV, float nDotL, float roughness)
{
	//fixed k = roughness * roughness;
	//float k = 0.5 + roughness * 0.5;
	//k *= k;
	float k = roughness * roughness * 0.5;
	float l = nDotL * (1.0 - k) + k;
	float v = nDotV * (1.0 - k) + k;
	return 0.25 / (l * v + 0.00001);
}

ColorNumber3 envir_brdf(ColorNumber3 specularColor, ColorNumber roughness, VectorNumber nDotV)
{
	const VectorNumber4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const VectorNumber4 c1 = { 1, 0.0425, 1.04, -0.04 };
	VectorNumber4 r = roughness * c0 + c1;
	VectorNumber a004 = min(r.x * r.x, exp2( -9.28 * nDotV)) * r.x + r.y;
	VectorNumber2 AB = fixed2(-1.04, 1.04) * a004 + r.zw;
	return specularColor * AB.x + AB.y;// * 0.35;
}

ColorNumber3 envir_brdf_nonmetal(ColorNumber roughness, VectorNumber nDotV)
{
	const VectorNumber2 c0 = { -1, -0.0275 };
	const VectorNumber2 c1 = { 1, 0.0425 };
	VectorNumber2 r = roughness * c0 + c1;
	return min( r.x * r.x, exp2( -9.28 * nDotV ) ) * r.x + r.y;
}

//pbr shading
inline ColorNumber3 PbrShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,ColorNumber3 lightColor,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,VectorNumber3 lightDir,
	ColorNumber4 mappingInfo,
	VectorNumber LMDAtten,
	#ifdef USE_SSSENABLE_ON
		VectorNumber3 sss,
		VectorNumber3 sssAlbedo,
	#endif
	#ifdef USE_ANISOTROPY_ON
		VectorNumber anisotropy,
	#endif 
	ColorNumber diffuseAlpha = 1.0,
	ColorNumber specularAlpha = 1.0)
{
	VectorNumber3 halfDir = normalize(lightDir + viewDir);
	
	ColorNumber3 diffuse = 0;
	ColorNumber3 specular = 0;
	
	VectorNumber nDotH = saturate(dot(normalWorld, halfDir));
	VectorNumber vDotH = saturate(dot(viewDir, halfDir));
	VectorNumber nDotL = dot(normalWorld, lightDir);
	nDotL = min(saturate(nDotL), LMDAtten);

#ifdef USE_SSSENABLE_ON
	nDotL = lerp(nDotL, pow(min(max(0, nDotL + 0.45) / 1.45, LMDAtten), 2), sss);

	VectorNumber sssa = smoothstep(0.51f, 0, (clamp(nDotL, -1, 0) + nDotL) / 2);
	VectorNumber sssb = saturate((0.53f - lerp(saturate(nDotL), saturate(-nDotL), 0.61f)) / 0.53f);
	VectorNumber3 finalSSS = sssb * sssa * sss * sssAlbedo * 2.35f * 0.3f;
	diffuse += albedo * (1 - metallic) * finalSSS * lightColor.rgb;
#endif

	diffuse += albedo * (1 - metallic) * nDotL * lightColor.rgb * diffuseAlpha;
#ifdef SHOW_DIFFUSE_ON
	return diffuse;
#endif

	ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
	float3 F = f_schlick(base, vDotH);
#ifdef USE_ANISOTROPY_ON
	float D = d_ggx(roughness, anisotropy);
#else
	float D = d_ggx(roughness, nDotH);
#endif
	float G = geometric(nDotV, nDotL, roughness);
	specular += D * F * G * (nDotL * lightColor.rgb) * specularAlpha;

#ifdef SHOW_SPECULAR_ON
	return specular;
#endif
#ifdef SHOW_SPECULARANDENVIRONMENT_ON
	return specular;
#endif

	return diffuse + specular;
}


//pbr only speacal
inline ColorNumber3 PbrShadingOnlySpecular(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,ColorNumber3 lightColor,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,
	ColorNumber4 mappingInfo,
#ifdef USE_ANISOTROPY_ON
	VectorNumber anisotropy,
#endif 	
	VectorNumber3 lightDir)
{
	VectorNumber3 halfDir = normalize(lightDir + viewDir);
	
	ColorNumber3 specular = 0;
	
	VectorNumber nDotH = saturate(dot(normalWorld, halfDir));
	VectorNumber vDotH = saturate(dot(viewDir, halfDir));
	VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
	
	ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
	float3 F = f_schlick(base, vDotH);
#ifdef USE_ANISOTROPY_ON
	float D = d_ggx(roughness, anisotropy);
#else
	float D = d_ggx(roughness, nDotH);
#endif
	float G = geometric(nDotV, nDotL, roughness);
	specular += D * F * G * (nDotL * lightColor.rgb);
	return specular;
}

//diffuse shading
inline ColorNumber3 DiffuseShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber3 lightColor,
	VectorNumber3 normalWorld,VectorNumber3 lightDir,
#ifdef USE_SSSENABLE_ON
	VectorNumber3 sss,
	VectorNumber3 sssAlbedo,
#endif

	ColorNumber diffuseAlpha = 1.0)
{
	ColorNumber3 diffuse = 0;
	
	VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
	VectorNumber LMDAtten = 1;
#ifdef USE_SSSENABLE_ON
	nDotL = lerp(nDotL, pow(min(max(0, nDotL + 0.45) / 1.45, LMDAtten), 2), sss);

	VectorNumber sssa = smoothstep(0.51f, 0, (clamp(nDotL, -1, 0) + nDotL) / 2);
	VectorNumber sssb = saturate((0.53f - lerp(saturate(nDotL), saturate(-nDotL), 0.61f)) / 0.53f);
	VectorNumber3 finalSSS = sssb * sssa * sss * sssAlbedo * 2.35f * 0.3f;
	diffuse += albedo * (1 - metallic) * finalSSS * lightColor.rgb;
#endif
		diffuse += albedo * (1 - metallic) * nDotL * lightColor.rgb * diffuseAlpha;
	return diffuse;
}

//point light atten
inline ColorNumber CalPointLightAtten(VectorNumber distance,VectorNumber range,VectorNumber3 posWorld)
{
	//leanear
	return saturate((range - distance) / range);
}

VectorNumber3 ShiftTangent(VectorNumber3 T, VectorNumber3 N, VectorNumber shift)
{
    VectorNumber3 shiftedT = T + (shift * N);
    return normalize(shiftedT);
}

VectorNumber StrandSpecular(VectorNumber3 T, VectorNumber3 V, VectorNumber3 L, VectorNumber exponent)
{
    VectorNumber3 H = normalize(L + V);
    VectorNumber dotTH = dot(T, H);
    VectorNumber sinTH = sqrt(1.0 - dotTH*dotTH);
    VectorNumber dirAtten = smoothstep(-1.0, 0.0, dot(T, H));

    return dirAtten * pow(sinTH, exponent);
	//return pow(sinTH, exponent);
}

/**
*
* Kajiya shading
*
**/

VectorNumber _KajiyaPrimaryShift;
VectorNumber _KajiyaSecondaryShift;
VectorNumber _KajiyaSpecExp1;
VectorNumber _KajiyaSpecExp2;
ColorNumber3 _KajiyaSpecularColor1;
ColorNumber3 _KajiyaSpecularColor2;

VectorNumber4 KajiyaLighting (VectorNumber3 tangent, VectorNumber3 normal, VectorNumber3 lightVec, ColorNumber3 lightColor,
                     VectorNumber3 viewVec,ColorNumber4 baseColor,VectorNumber3 mask)
{
	//VectorNumber3 mask = tex2D(_MappingTex, uv).rgb;
    // shift tangents
    VectorNumber shiftTex = mask.r - 0.5;
    VectorNumber3 t1 = ShiftTangent(tangent, normal, _KajiyaPrimaryShift + shiftTex);
    VectorNumber3 t2 = ShiftTangent(tangent, normal, _KajiyaSecondaryShift + shiftTex);

    // diffuse lighting
    VectorNumber diffuse = clamp(lerp(0.25, 1.0, dot(normal, lightVec)), 0, 1);

    // specular lighting
	VectorNumber s = StrandSpecular(t1, viewVec, lightVec, _KajiyaSpecExp1);
    VectorNumber3 specular = _KajiyaSpecularColor1.rgb * VectorNumber3(s, s, s);
    // add second specular term
    VectorNumber specMask = mask.g; 
	s = StrandSpecular(t2, viewVec, lightVec, _KajiyaSpecExp2);
    specular += _KajiyaSpecularColor2.rgb * VectorNumber3(specMask,specMask,specMask) * VectorNumber3(s, s, s);

    // Final color
    VectorNumber4 o;
	//VectorNumber4 baseColor = tex2D(_MainTex, uv);
    //o.rgb = baseColor.rgb;
	o.rgb = (VectorNumber3(diffuse, diffuse, diffuse) + specular) * baseColor.rgb * lightColor;
    o.rgb *= mask.b; 
    o.a = baseColor.a;

    return o;
}

//Kajiya shading

/**
*
* diffraction 衍射
*
**/

/*struct VertexOutputForwardBaseEx
{
	UNITY_POSITION(pos);
	VectorNumber4 tex                          : TEXCOORD0;
	VectorNumber3 eyeVec                        : TEXCOORD1;
	VectorNumber4 tangentToWorldAndPackedData[3]    : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
	VectorNumber4 ambientOrLightmapUV           : TEXCOORD5;    // SH or Lightmap UV
	UNITY_SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)

	//#ifdef REALTIME_REFLECTION_ON
	//VectorNumber4 screenPos                 : TEXCOORD8;
	//#endif
	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
	#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
	VectorNumber3 posWorld                  : TEXCOORD8;
		#ifdef NEED_SCREENPOS
	VectorNumber4 screenPos : TEXCOORD9;
		#endif
	#else
		#ifdef NEED_SCREENPOS
	VectorNumber4 screenPos : TEXCOORD8;
		#endif
	#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};*/

float _RoughX;
float4 _HiliteColor;
float _SpacingX;
float _FresnelFactor;

struct DiffractionVertexInput
{
    VectorNumber4 vertex   : POSITION;
    VectorNumber3 normal    : NORMAL;
    VectorNumber3 tangent   : TANGENT;
	VectorNumber4 uv0       : TEXCOORD0;
	
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct DiffractionV2F
{
	UNITY_POSITION(vertex);
	
	VectorNumber2 tex : TEXCOORD0;
	
	VectorNumber3 normalWorld : TEXCOORD1;
	VectorNumber3 tangentWorld : TEXCOORD2;
	float4 posWorld : TEXCOORD3;
	
#ifdef NEED_ENV_ON
	VectorNumber4 worldRefl : TEXCOORD4;
#endif
	
	UNITY_FOG_COORDS(5)
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

float3 blend3(float3 x)
{
    float3 y = 1- x * x;
    y = max(y, float3(0,0,0));
 
    return y;
}
 
//Fresnel approximation, power = 5
float fastFresnel(float3 V, float3 H, float R0)
{
    float icosVN = saturate(1 - dot(V, H));
    float i2 = icosVN * icosVN, i4 = i2 * i2;
    return R0 + (1 - R0) * (i4 * icosVN);
}
 
DiffractionV2F diffractionVert (DiffractionVertexInput v)
{
    DiffractionV2F o;
 
    o.vertex = UnityObjectToClipPos(v.vertex);
	o.tex = TRANSFORM_TEX(v.uv0, _MainTex);

    /*o.normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
    float3 tangent = cross(v.normal, normalize(v.vertex));
    o.tangent = mul((float3x3)UNITY_MATRIX_IT_MV, tangent);
    o.pos = mul(UNITY_MATRIX_MV, v.vertex);*/
	
	o.normalWorld = normalize(UnityObjectToWorldDir(v.normal.xyz));
	o.tangentWorld = normalize(UnityObjectToWorldDir(v.tangent.xyz));
	o.posWorld = mul(unity_ObjectToWorld,v.vertex);
 
#ifdef NEED_ENV_ON
    //
    float3 worldPos = o.posWorld;//mul(unity_ObjectToWorld, v.vertex);
    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
    float3 worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
    float3 halfv = normalize(viewDir + _WorldSpaceLightPos0.xyz);
    o.worldRefl.xyz = reflect(-viewDir, worldNormal);
    o.worldRefl.w = fastFresnel(viewDir, halfv, _FresnelFactor);
#endif

    UNITY_TRANSFER_FOG(o,o.vertex);
 
    return o;
}

float4 diffractionFrag (DiffractionV2F i) : SV_Target
{
    //sample the texture
    //float4 col = float4(0,0,0,1);
	float4 col = tex2D(_MainTex, i.tex * _MainTex_ST.xy + _MainTex_ST.zw) * _Color;
 
    float3 posWorld = i.posWorld;
 
    /*float3 lightPos = mul(unity_WorldToObject, float4(_WorldSpaceLightPos0.xyz,1));
    lightPos = mul(UNITY_MATRIX_MV, float4(lightPos,1));
    float3 cameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz,1));
    cameraPos= mul(UNITY_MATRIX_MV, float4(cameraPos,1));*/
	
	float3 lightPos = _WorldSpaceLightPos0.xyz;
	float3 cameraPos = _WorldSpaceCameraPos.xyz;
 
    float3 lightDir = normalize(lightPos - posWorld);
 
    float3 viewDir = normalize(cameraPos - posWorld);
 
    //float3 halfv = lightDir + viewDir;
	float3 halfv = normalize(lightDir + viewDir);
 
    //float3 normal = normalize(i.normal);
    //float3 tangent = normalize(i.tangent);
	float3 normal = i.normalWorld;
    float3 tangent = i.tangentWorld;
 
    float u = dot(tangent, normalize(halfv));
 
    u = 2 * u * dot(normalize(halfv), viewDir);
 
    float vz = dot(normal, halfv);
 
    float e = u * _RoughX / vz;
 
    float c = exp(-e * e);
 
    float4 anis = _HiliteColor * c.xxxx;
 
    anis.w = 1;
    u = u * _SpacingX;
 
    if(u < 0)
		u = -u;
 
    float vx0;
 
    float4 cdiff = float4(0,0,0,1);
 
    for(int j = 1; j < 8; j++)
    {
		vx0 = 2 * u / j - 1;
		cdiff.xyz += blend3(float3(4 * (vx0 - 0.75), 4 * (vx0 - 0.5), 4 * (vx0 - 0.25)));
    }
 
    col += (0.8 * cdiff + anis);
 
    //col.xyz = col.xyz;
 
#ifdef NEED_ENV_ON
	float3 envColor = texCUBE(_EnvCubeMap, i.worldRefl.xyz);
	float fresnel = i.worldRefl.w;
    col.xyz = lerp(col.xyz, envColor, fresnel);
#endif
    //apply fog
    UNITY_APPLY_FOG(i.fogCoord,col);
 
    return col;
}

//diffraction 衍射

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
/*#ifdef _TANGENT_TO_WORLD
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
#endif*/

/*half3 PerPixelWorldNormal(float4 i_tex, half4 tangentToWorld[3])
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
}*/

VectorNumber3 PerPixelWorldNormal(VectorNumber4 i_tex, VectorNumber4 tangentToWorld[3], VectorNumber4 normalColor)
{
#ifdef _NORMALMAP
    VectorNumber3 tangent = normalize(tangentToWorld[0].xyz);
    VectorNumber3 binormal = normalize(tangentToWorld[1].xyz);
    VectorNumber3 normal = normalize(tangentToWorld[2].xyz);
		
	#ifdef USE_FADE_TEX_ON
		normalColor = CalFadedNormal(normalColor,i_tex);
	#endif
	
	normalColor.xy = normalColor.xy * 2 - 1;

	//#ifdef NEED_BUMP_SCALE
		normalColor.xy *= _BumpScale;
	//#endif

	VectorNumber3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
	VectorNumber3 normalWorld = normalize(normal + normalOffset);
	return normalWorld;
#else
    VectorNumber3 normalWorld = normalize(tangentToWorld[2].xyz);
	return normalWorld;
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
	ColorNumber emission;
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

	VectorNumber4 normalColor = tex2D(_BumpMap, i_tex /** _BumpMap_ST.xy + _BumpMap_ST.zw*/);

    FragmentCommonData o = UNITY_SETUP_BRDF_INPUT (i_tex);
    o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld, normalColor);
	#ifdef	USE_EMISSION_ON
	o.emission = normalColor.w;
	#endif
	o.ao = normalColor.z;
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
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,
	ColorNumber4 mappingInfo,
	VectorNumber LMDAtten,
#ifdef USE_SSSENABLE_ON
	VectorNumber3 sss,
	VectorNumber3 sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
	VectorNumber anisotropy,
#endif 
	ColorNumber diffuseAlpha = 1.0)
{
	VectorNumber3 lightDir = dirLight.dir;

	#ifdef _NON_USE_PBR_GLOSSY_ON
	return DiffuseShading(albedo, metallic, dirLight.color, normalWorld, lightDir,
#ifdef USE_SSSENABLE_ON
		sss,
		sssAlbedo,
#endif
		diffuseAlpha);
	#else
	return PbrShading(albedo, metallic, roughness, dirLight.color, 
		normalWorld, viewDir, nDotV, lightDir,
		mappingInfo,
		LMDAtten,
#ifdef USE_SSSENABLE_ON
		sss,
		sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
		anisotropy,
#endif 
		diffuseAlpha) ;
	#endif
}

inline ColorNumber3 AllDirectLightsShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,
	ColorNumber4 mappingInfo,
	VectorNumber LMDAtten,
#ifdef USE_SSSENABLE_ON
	VectorNumber3 sss,
	VectorNumber3 sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
	VectorNumber anisotropy,
#endif 
	ColorNumber diffuseAlpha = 1.0)
{
	ColorNumber3 color = ColorNumber3(0,0,0);
	
	for(int i = 0;i < _mDirectLightCount;i++)
	{
		DirectLight dirLight = _mDirectLights[i];
		color += PbrDirectLightShading(albedo,metallic,roughness,dirLight,posWorld,normalWorld,viewDir,nDotV,
			mappingInfo,
			LMDAtten,
#ifdef USE_SSSENABLE_ON
			sss,
			sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
			anisotropy,
#endif 
			diffuseAlpha);
	}
	
	return color;
}

inline ColorNumber3 KajiyaAllDirectLightsShading(ColorNumber4 baseColor,VectorNumber3 mask,VectorNumber3 tangentWorld,VectorNumber3 normalWorld,VectorNumber3 viewDir)
{
	ColorNumber3 color = ColorNumber3(0,0,0);
	
	for(int i = 0;i < _mDirectLightCount;i++)
	{
		VectorNumber3 lightDir = _mDirectLights[i].dir;
		ColorNumber3 lightColor = _mDirectLights[i].color;
		color += KajiyaLighting(tangentWorld,normalWorld,lightDir,lightColor,viewDir,baseColor,mask).rgb;
	}
	
	return color;
}

inline ColorNumber3 AllDirectLightsShadingDiffuse(ColorNumber3 albedo,ColorNumber metallic,VectorNumber3 normalWorld,
#ifdef USE_SSSENABLE_ON
	VectorNumber3 sss,
	VectorNumber3 sssAlbedo,
#endif
	ColorNumber diffuseAlpha = 1.0)
{
	ColorNumber3 color = ColorNumber3(0,0,0);
	
	for(int i = 0;i < _mDirectLightCount;i++)
	{
		DirectLight dirLight = _mDirectLights[i];
		VectorNumber3 lightDir = dirLight.dir;
		color += DiffuseShading(albedo, metallic, dirLight.color, normalWorld, lightDir,
#ifdef USE_SSSENABLE_ON
			sss,
			sssAlbedo,
#endif
			diffuseAlpha);
	}
	
	return color;
}

inline ColorNumber3 AllDirectLightsShadingOnlySpecular(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir,
	ColorNumber4 mappingInfo,
#ifdef USE_ANISOTROPY_ON
	VectorNumber anisotropy,
#endif 		
	VectorNumber nDotV)
{
	ColorNumber3 color = ColorNumber3(0,0,0);
	
	for(int i = 0;i < _mDirectLightCount;i++)
	{
		DirectLight dirLight = _mDirectLights[i];
		VectorNumber3 lightDir = dirLight.dir;
		color += PbrShadingOnlySpecular(albedo, metallic, roughness, dirLight.color, normalWorld, viewDir, nDotV,
			mappingInfo,
#ifdef USE_ANISOTROPY_ON
			anisotropy,
#endif 				
			lightDir);
	}
	
	return color;
}

//one point light shading
inline ColorNumber3 PbrPointLightShading(ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,PointLight pointLight,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV, 
	ColorNumber4 mappingInfo,
	VectorNumber LMDAtten,
#ifdef USE_SSSENABLE_ON
	VectorNumber3 sss,
	VectorNumber3 sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
	VectorNumber anisotropy,
#endif 
	ColorNumber diffuseAlpha = 1.0)
{
	VectorNumber3 lightDir = pointLight.positionWS.xyz - posWorld;
	
	ColorNumber atten = CalPointLightAtten(length(lightDir),pointLight.range, posWorld);
	
	lightDir = normalize(lightDir);
	
	#ifdef _NON_USE_PBR_GLOSSY_ON
	return DiffuseShading(albedo, metallic, pointLight.color * pointLight.intensity, normalWorld, lightDir,
#ifdef USE_SSSENABLE_ON
		sss,
		sssAlbedo,
#endif
		diffuseAlpha) * atten;
	#else
	return PbrShading(albedo, metallic, roughness, pointLight.color * pointLight.intensity,normalWorld, viewDir, nDotV, lightDir,
		mappingInfo,
		LMDAtten,
#ifdef USE_SSSENABLE_ON
		sss,
		sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
		anisotropy,
#endif 
		diffuseAlpha) * atten;
	#endif
}

//kajiya one point light shading
inline ColorNumber3 KajiyaPointLightShading(ColorNumber4 baseColor,VectorNumber3 mask,PointLight pointLight,VectorNumber3 posWorld,
	VectorNumber3 tangentWorld,VectorNumber3 normalWorld,VectorNumber3 viewDir)
{
	VectorNumber3 lightDir = pointLight.positionWS.xyz - posWorld;
	
	ColorNumber atten = CalPointLightAtten(length(lightDir),pointLight.range, posWorld);
	
	lightDir = normalize(lightDir);
	
	return KajiyaLighting(tangentWorld,normalWorld,lightDir,
		pointLight.color * pointLight.intensity,viewDir,baseColor,mask).rgb * atten;
}

//all point lights shadding
inline ColorNumber3 AllPointLightsShading(VectorNumber2 screenPosXY,
	ColorNumber3 albedo,ColorNumber metallic,ColorNumber roughness,VectorNumber3 posWorld,
	VectorNumber3 normalWorld,VectorNumber3 viewDir, VectorNumber nDotV,
	ColorNumber4 mappingInfo,
	#ifdef USE_SSSENABLE_ON
		VectorNumber3 sss,
	#endif
	#ifdef USE_ANISOTROPY_ON
		VectorNumber anisotropy,
	#endif
	ColorNumber diffuseAlpha = 1.0)
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
		
		color += PbrPointLightShading(albedo,metallic,roughness,pointLight,posWorld,normalWorld,viewDir,nDotV,
			mappingInfo,
			LMDAtten,
#ifdef USE_SSSENABLE_ON
			sss,
			sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
			anisotropy,
#endif 
			diffuseAlpha);
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
		
		color += PbrPointLightShading(albedo,metallic,roughness,pointLight,posWorld,normalWorld,viewDir,nDotV,
			mappingInfo,
			LMDAtten,
#ifdef USE_SSSENABLE_ON
			sss,
			sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
			anisotropy,
#endif 
			diffuseAlpha);
		
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

//Kajiya all point lights shadding
inline ColorNumber3 KajiyaAllPointLightsShading(VectorNumber2 screenPosXY,ColorNumber4 baseColor,VectorNumber3 mask,
	VectorNumber3 posWorld,VectorNumber3 tangentWorld,VectorNumber3 normalWorld,VectorNumber3 viewDir)
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
			
		color += KajiyaPointLightShading(baseColor,mask,pointLight,posWorld,tangentWorld,normalWorld,viewDir);
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
		
		color += KajiyaPointLightShading(baseColor,mask,pointLight,posWorld,tangentWorld,normalWorld,viewDir);
		
		head = linked.y;
	}
	
#endif

	return color;
}

//all point lights shadding
inline ColorNumber3 AllPointLightsShadingDiffuse(VectorNumber2 screenPosXY,
	ColorNumber3 albedo,ColorNumber metallic,VectorNumber3 posWorld,VectorNumber3 normalWorld,
#ifdef USE_SSSENABLE_ON
	VectorNumber3 sss,
	VectorNumber3 sssAlbedo,
#endif
	ColorNumber diffuseAlpha = 1.0)
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
	
		color += DiffuseShading(albedo, metallic, pointLight.color * pointLight.intensity, normalWorld, lightDir,
#ifdef USE_SSSENABLE_ON
			sss,
			sssAlbedo,
#endif
			diffuseAlpha) * atten;
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
		
		color += DiffuseShading(albedo, metallic, pointLight.color * pointLight.intensity, normalWorld, lightDir,
#ifdef USE_SSSENABLE_ON
			sss,
			sssAlbedo,
#endif
			diffuseAlpha) * atten;
		
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
/*
	pbr shading main
*/


ColorNumber _FogFactor;

//pbr vertex base
VertexOutputForwardBaseEx pbrVertBase(VertexInput v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputForwardBaseEx o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBaseEx, o);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	VectorNumber4 posWorld = mul(unity_ObjectToWorld, v.vertex);
#ifdef USE_ANITREE_ON
    float4 offset;
    float phase = dot(posWorld.xz,0.1);
    offset.xz = cos(_Time.y*_Frequency+phase)*v.color.g*_Amplitude;
	offset.y = sin(_Time.y*_Frequency01+phase)*v.color.r*_Amplitude01;
	offset.xyz *= normalize(_WindDir);
	offset.w = 0;
	v.vertex+=offset;
#endif
#if UNITY_REQUIRE_FRAG_WORLDPOS
	#if UNITY_PACK_WORLDPOS_WITH_TANGENT
	o.tangentToWorldAndPackedData[0].w = posWorld.x;
	o.tangentToWorldAndPackedData[1].w = posWorld.y;
	o.tangentToWorldAndPackedData[2].w = posWorld.z;
	#else
	o.posWorld = posWorld.xyz;
	#endif
#endif

	o.pos = UnityObjectToClipPos(v.vertex);

	//o.tex.xy = v.uv0;
	o.tex = TexCoords(v);
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);

	VectorNumber3 normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
#ifdef _TANGENT_TO_WORLD
	/*float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

	float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
	o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
	o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
	o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];*/

	o.tangentToWorldAndPackedData[0].xyz = normalize(UnityObjectToWorldDir(v.tangent.xyz));
	VectorNumber vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
	o.tangentToWorldAndPackedData[1].xyz = cross(o.tangentToWorldAndPackedData[0].xyz, normalWorld) * vv * v.tangent.w;
	o.tangentToWorldAndPackedData[2].xyz = normalWorld;
#else
	o.tangentToWorldAndPackedData[0].xyz = 0;
	o.tangentToWorldAndPackedData[1].xyz = 0;
	o.tangentToWorldAndPackedData[2].xyz = normalWorld;
#endif

	//We need this for shadow receving
	UNITY_TRANSFER_SHADOW(o, v.uv1);

#ifdef NEED_SCREENPOS
	o.screenPos = ComputeScreenPos(o.pos);
#endif

#ifdef USE_COMBINE_PARAMS
	o.fParamsIndex = v.color.x;
#endif

	o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);
#ifdef USE_ANITREE_ON
   o.treeFog=SimulateFog(o.pos);
#endif
	UNITY_TRANSFER_FOG(o, o.pos);
	return o;
}

//pbr vertex add
VertexOutputForwardBaseAdd pbrVertAdd(VertexInput v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputForwardBaseAdd o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBaseAdd, o);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	VectorNumber4 posWorld = mul(unity_ObjectToWorld, v.vertex);

#if UNITY_REQUIRE_FRAG_WORLDPOS
#if UNITY_PACK_WORLDPOS_WITH_TANGENT
	o.tangentToWorldAndPackedData[0].w = posWorld.x;
	o.tangentToWorldAndPackedData[1].w = posWorld.y;
	o.tangentToWorldAndPackedData[2].w = posWorld.z;
#else
	o.posWorld = posWorld.xyz;
#endif
#endif

	o.pos = UnityObjectToClipPos(v.vertex);

	//o.tex.xy = v.uv0;
	o.tex = TexCoords(v);
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);

	VectorNumber3 normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
#ifdef _TANGENT_TO_WORLD

	o.tangentToWorldAndPackedData[0].xyz = normalize(UnityObjectToWorldDir(v.tangent.xyz));
	VectorNumber vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
	o.tangentToWorldAndPackedData[1].xyz = cross(o.tangentToWorldAndPackedData[0].xyz, normalWorld) * vv * v.tangent.w;
	o.tangentToWorldAndPackedData[2].xyz = normalWorld;

#else
	o.tangentToWorldAndPackedData[0].xyz = 0;
	o.tangentToWorldAndPackedData[1].xyz = 0;
	o.tangentToWorldAndPackedData[2].xyz = normalWorld;
#endif

	//We need this for shadow receving
	UNITY_TRANSFER_SHADOW(o, v.uv1);

	return o;
}
//params

#ifdef USE_COMBINE_PARAMS
ColorNumber _IndirectDiffuseFactors[10];
ColorNumber _IndirectSpecFactors[10];
#else
ColorNumber _IndirectDiffuseFactor;
ColorNumber _IndirectSpecFactor;
#endif

ColorNumber4 _IndirectSpecColor;
VectorNumber4 _IndirectLightDir;

ColorNumber _MetalFactor;
ColorNumber _RoughnessFactor;

#ifdef _USE_SCREEN_SSS_ON
uniform sampler2D _SSSTex;

ColorNumber4 _skinTopLayerColor;
ColorNumber4 _skinSubLayerColor;
ColorNumber _skinSubLayerFactor;

#endif

//#ifdef ST2_LAND
//ColorNumber st2BlackFactor;
//#endif

//修正光源方向
VectorNumber3 FixLightDir(VectorNumber3 lightDir, VectorNumber3 cameraDir)
{
	VectorNumber nDotL = dot(lightDir, cameraDir);
	VectorNumber f = step(0, nDotL);

	return f * lightDir + (1.0 - f) * VectorNumber3(-lightDir.x, lightDir.y, -lightDir.z);

	/*if (nDotL < 0)
		return VectorNumber3(-lightDir.x, lightDir.y, -lightDir.z);
	else
		return lightDir;*/
}

VectorNumber3 _CameraDir;

#define PBR_BASE_INIT(gi) UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);\
	FRAGMENT_SETUP(s)\
	UNITY_SETUP_INSTANCE_ID(i);\
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);\
	UnityLight mainLight = MainLight();\
	UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);\
	ColorNumber occlusion = _Occlusion;\
	UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

//pbr frag standard base
ColorNumber4 pbrFragStandardBase(VertexOutputForwardBaseEx i) : COLOR
{
	//PBR_BASE_INIT(gi)
	FRAGMENT_SETUP(s)
	UNITY_SETUP_INSTANCE_ID(i); 
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); 
	UnityLight mainLight = MainLight();

	VectorNumber3 viewDir = normalize(UnityWorldSpaceViewDir(s.posWorld));

#if !defined(USE_NRP_ON) && defined(TYPE_CHAR) && defined(USE_FACE_TO_CAMERA_LIGHT)
	mainLight.dir = FixLightDir(mainLight.dir, normalize(VectorNumber3(-_CameraDir.x, 0, -_CameraDir.z)));
	//mainLight.dir = FixLightDir(mainLight.dir, normalize(VectorNumber3(viewDir.x, 0, viewDir.z)));
#endif

#ifdef SHADOWS_SCREEN //如果没有这个宏，强制不进行衰减计算
	UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);
#else
	fixed atten = 1;
#endif

#ifdef USE_COMBINE_PARAMS
	int paramIndex = (i.fParamsIndex * 10.0 + 0.001);//0.001是为了减少float误差
#endif

	ColorNumber occlusion = _Occlusion;
	UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, mainLight);
	

	/*#ifdef ST2_LAND
		#ifdef LIGHTMAP_ON
		// Baked lightmaps
			#if !(defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN))
			gi.indirect.diffuse = gi.indirect.diffuse * atten;
			#endif
		#endif
	#endif*/

	/*#if defined(ST2_LAND) && defined(SHADOWS_SHADOWMASK)
			return float4(1,0,0,1);
	#endif

	#if defined(ST2_LAND) && !defined(LIGHTMAP_SHADOW_MIXING)
			return float4(0,1,0,1);
	#endif

	#if defined(ST2_LAND) && !defined(SHADOWS_SCREEN)
			return float4(0,0,1,1);
	#endif*/

	//test
	//gi.indirect.diffuse = float3(1,1,1);

	VectorNumber2 uv = i.tex.xy;

	VectorNumber3 normalWorld = s.normalWorld;
#ifdef SHOW_NORMAL_ON
	return fixed4(normalWorld, 1);
#endif
	//return ColorNumber4((normalWorld.xyz + 1) / 2,1);

	//VectorNumber3 lightDir;
	//平行光
	//if(mainLight.dir.x == 0.0 && mainLight.dir.y == 0.0 && mainLight.dir.z == 0.0)
	//	lightDir = normalWorld;
	//else

#if defined(TYPE_SCENE)
	gi.light.color = gi.light.color;
#else
	#ifdef USE_ROLELIGHYINTENSITY_ON
		gi.light.color *= float4(_RoleLightIntensity, _RoleLightIntensity, _RoleLightIntensity, _RoleLightIntensity);
	#endif
#endif

#ifdef ST2_LAND
	#ifdef USE_MATERIAL_DIR_ON
	VectorNumber3 lightDir = -normalize(_IndirectLightDir.xyz);
	#else
	VectorNumber3 lightDir = mainLight.dir;
	#endif
	//gi.light.color = mainLight.color;
#else
	#ifdef USE_MATERIAL_DIR_ON
	VectorNumber3 lightDir = -normalize(_IndirectLightDir.xyz);
	#else
	VectorNumber3 lightDir = gi.light.dir;
	#endif

#endif

	ColorNumber3 finalColor = 0;

	VectorNumber nDotV = saturate(dot(normalWorld, viewDir));
	ColorNumber4 albedo = tex2D(_MainTex, uv /** _MainTex_ST.xy + _MainTex_ST.zw*/) ;

#ifdef USE_ALPHA_TEST_ON
	clip(albedo.a - _Cutoff);
#endif

#ifdef USE_COMBINE_PARAMS
	ColorNumber4 surfaceColor = _SurfaceColors[paramIndex];
#else
	ColorNumber4 surfaceColor = _SurfaceColor;
#endif

	albedo.rgb = albedo.rgb * _Color.rgb * surfaceColor.rgb;

#ifdef USE_TATTOO_TEX_ON
	ColorNumber4 tattoo = tex2D(_TattooTex, (uv /** _MainTex_ST.xy + _MainTex_ST.zw*/)) * _Color * surfaceColor;
	albedo.rgb = lerp(albedo.rgb, tattoo.rgb, tattoo.a * _TattooToggle);
#endif


	ColorNumber4 mappingInfo = tex2D(_MappingTex, uv /** _MappingTex_ST.xy + _MappingTex_ST.zw*/);
	VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
	VectorNumber3 halfDir = normalize(lightDir + viewDir);
	VectorNumber nDotH = saturate(dot(normalWorld, halfDir));
	VectorNumber LMDAtten=1;
	VectorNumber3 sssAlbedo = 0;
	VectorNumber3 sss = 0;
	
#ifdef USE_SELFSHADOW_ON
	float4 shadowPos = float4(s.posWorld.xyz, 1);
	float4 ndcpos = mul(_HQCharCameraVP, shadowPos);
	ndcpos.xyz /= ndcpos.w;
	float3 uvpos = ndcpos * 0.5 + 0.5;
	LMDAtten = PCFForNoTrans(uvpos.xy, ndcpos.z, _Bias);
	//return LMDAtten;
#endif

	nDotL = min(saturate(nDotL), LMDAtten);

#ifdef USE_SSSENABLE_ON
	sssAlbedo = saturate(albedo - max(max(max(albedo.x, albedo.y), albedo.z) - 0.39, 0.1));
	sss = clamp(mappingInfo.y * 2 - 1, 0, 1);
	nDotL = lerp(nDotL, pow(min(max(0, nDotL + 0.45) / 1.45, LMDAtten), 2), sss);
#endif

#ifdef SHOW_SSSMASKCOLOR_ON
	return mappingInfo.y;
	finalColor = sss;
	finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
	return fixed4(finalColor,1);
#endif

#ifdef USE_ANISOTROPY_ON
	ColorNumber4 anisoColor = tex2D(_AnisoTex, uv);
	VectorNumber dotTH = dot(halfDir, -i.tangentToWorldAndPackedData[1].xyz + (anisoColor.b * -0.5) * 2 * normalWorld);
	VectorNumber sinTHTH = 1 - dotTH * dotTH;
	VectorNumber sinTHTH2 = sinTHTH * sinTHTH;
	VectorNumber anisotropy = lerp(nDotH, sinTHTH2 * sinTHTH2, step(mappingInfo.y, 0.25));
#endif
#ifdef SHOW_ANISOTROPICMASKCOLOR_ON
	return tex2D(_AnisoTex, uv).b;
	//VectorNumber dotTH = dot(halfDir, -i.tangentToWorldAndPackedData[1].xyz + (anisoColor.b * -0.5) * 2 * normalWorld);
	//VectorNumber sinTHTH = 1 - dotTH * dotTH;
	//VectorNumber sinTHTH2 = sinTHTH * sinTHTH;
	//VectorNumber anisotropy = lerp(nDotH, sinTHTH2 * sinTHTH2, step(mappingInfo.y, 0.25));
	//return anisotropy;
#endif


	ColorNumber3 envShadow = lerp(
#ifdef USE_COMBINE_PARAMS
		_EnvShadowColors[paramIndex]
#else
		_EnvShadowColor
#endif
		, 1, nDotL);

#ifdef USE_FADE_TEX_ON
	albedo.rgb = CalFadedAlbedoColor(albedo.rgb,uv);
#endif
#ifdef	USE_GAMMA_SPACE_ON
#else
	albedo.rgb = albedo.rgb * albedo.rgb;
#endif
	

#ifdef ST2_LAND
	ColorNumber roughness = lerp(0.04, 1, saturate(mappingInfo.z * _RoughnessFactor));
	ColorNumber metallic = saturate(mappingInfo.x * _MetalFactor);
#else
	ColorNumber roughness = lerp(0.04, 1, saturate(mappingInfo.z));
	ColorNumber metallic = mappingInfo.x;
#endif

#ifdef SHOW_METALLICMASKCOLOR_ON
	return metallic;
#endif 
#ifdef SHOW_ROUGHNESSMASKCOLOR_ON
	return roughness;
#endif

//直接光照计算
#ifdef _NON_USE_PBR_GLOSSY_ON
	
	#ifndef ST2_LAND
		finalColor += DiffuseShading(albedo, metallic, gi.light.color.rgb, normalWorld, lightDir,
			#ifdef USE_SSSENABLE_ON
					sss,
					sssAlbedo,
			#endif
			1);
	#endif	
#else

	#ifdef USE_COMBINE_PARAMS
	ColorNumber indirectSpecFactor = _IndirectSpecFactors[paramIndex];
	#else
	ColorNumber indirectSpecFactor = _IndirectSpecFactor;
	#endif

	#ifdef ST2_LAND
	finalColor += PbrShadingOnlySpecular(albedo, metallic, roughness, (gi.indirect.diffuse * indirectSpecFactor), normalWorld, viewDir, nDotV,
		mappingInfo,
		#ifdef USE_ANISOTROPY_ON
				 anisotropy,
		#endif 		
		lightDir).rgb;
	#else

	finalColor += PbrShading(albedo, metallic, roughness, gi.light.color.rgb, normalWorld, viewDir, nDotV, lightDir,
		mappingInfo,
		LMDAtten,
#ifdef USE_SSSENABLE_ON
		sss,
		sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
		anisotropy,
#endif 
		1, indirectSpecFactor).rgb;
	#endif
#endif

#ifdef SHOW_DIFFUSE_ON
	finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
	return fixed4(finalColor, 1);
#endif

#ifdef SHOW_SPECULAR_ON
	finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
	return float4(finalColor, 1);
#endif
#ifdef	SHOW_SPECULARANDENVIRONMENT_ON
	fixed3 spec = finalColor;
#endif
//间接光照计算
	//sh and lightmaps
	//ambient += max(half3(0,0,0), ShadeSH9 (half4(normal, 1.0)));
	//finalColor += albedo * (1 - metallic) * max(half3(0,0,0), ShadeSH9 (half4(normalWorld, 1.0))) * _IndirectDiffuseFactor;

#ifdef USE_COMBINE_PARAMS
	ColorNumber indirectDiffuseFactor = _IndirectDiffuseFactors[paramIndex];
#else
	ColorNumber indirectDiffuseFactor = _IndirectDiffuseFactor;
#endif

#ifdef ST2_LAND
	ColorNumber3 indirectDiffuse = gi.indirect.diffuse * indirectDiffuseFactor;
	indirectDiffuse = lerp(gi.indirect.diffuse, indirectDiffuse, gi.indirect.diffuse);

	finalColor += lerp(albedo.rgb * indirectDiffuse * (1 - metallic),


		DiffuseShading(albedo, metallic, indirectDiffuse, normalWorld, lightDir,
		#ifdef USE_SSSENABLE_ON
					sss,
					sssAlbedo,
		#endif	
			1),
		
		_LightIntensity);
#else
	#ifdef USE_NRP_ON
		//固定球谐
		VectorNumber3 sh = LMDShadeSH9(float4(normalWorld, 1));

		//return float4(sh, 1);

		//sss球谐
		VectorNumber3 s2 = (2.0 - nDotV) * sssAlbedo * sss;
		//环境光球谐
		finalColor +=  albedo.rgb * (1 - metallic) *(envShadow * sh + s2 * sh) ;
	#else
		#ifdef USE_LERP_LIGHT_ON

				finalColor = lerp(finalColor.rgb * gi.indirect.diffuse, 

					lerp(albedo.rgb, albedo.rgb * (1 - metallic) * gi.indirect.diffuse * indirectDiffuseFactor, _LightIntensity),

					_LightLerpFactor);
		#else
			#if defined(TYPE_SCENE)
				finalColor += lerp(albedo.rgb, albedo.rgb * (1 - metallic) * gi.indirect.diffuse * indirectDiffuseFactor, _LightIntensity);
			#else
				//固定球谐
				VectorNumber3 sh = gi.indirect.diffuse * indirectDiffuseFactor;

				//return float4(gi.indirect.diffuse, 1);

				//sss球谐
				VectorNumber3 s2 = (2 - nDotV) * sssAlbedo * sss;
				//环境光球谐
				finalColor += albedo.rgb * (1 - metallic) * (envShadow * sh + s2 * sh);
			#endif
		#endif
	#endif
#endif

#ifdef SHOW_ENVIRONMENT_ON
	finalColor = 0;
#endif

//环境光计算
#ifdef NEED_ENV_ON	
	//实时反射计算
	#ifdef REALTIME_REFLECTION_ON
		VectorNumber2 uvxy = (i.screenPos.xy / i.screenPos.w);
		#ifdef BLUR_ON
			ColorNumber4 envir = GetBlurColor(uvxy, int(roughness * 8)) * _ReflectionFactor;
		#else
			ColorNumber4 envir = tex2Dlod(_ReflectionTex, VectorNumber4(uvxy, int(roughness * 8), int(roughness * 8))) * _ReflectionFactor;
		#endif

	#else
		VectorNumber3 refDir = normalize(reflect(-viewDir, normalWorld));
		ColorNumber4 envir = texCUBElod(_EnvCubeMap, VectorNumber4(refDir, int(roughness * 8)));
		envir.rgb *= envir.a;
	#endif
	//金属计算
	#if _HASMETAL_ON
		ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
		finalColor += lerp(0.6, 1, nDotL) * envir * envir_brdf(base, roughness, nDotV) * envShadow;
	#else
		finalColor += lerp(0.6, 1, nDotL) * envir * envir_brdf_nonmetal(roughness, nDotV) * envShadow;
	#endif
#endif

#ifdef SHOW_ENVIRONMENT_ON
		return envir;
		finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
		return fixed4(finalColor,1);
#endif
#ifdef SHOW_SPECULARANDENVIRONMENT_ON
		finalColor = spec;
		finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
		return fixed4(finalColor, 1);
#endif


//不使用forward plus渲染
#ifndef _FORCE_NO_USE_FORWARD_PLUS_RENDER_ON
	#ifdef _USE_FORWARD_PLUS_RENDER_ON
	finalColor += AllDirectLightsShading(albedo.xyz, metallic, roughness, s.posWorld.xyz, normalWorld, viewDir, nDotV,
		mappingInfo,
		LMDAtten,
#ifdef USE_SSSENABLE_ON
		sss,
		sssAlbedo,
#endif
#ifdef USE_ANISOTROPY_ON
		anisotropy,
#endif 
		1);

	//test
	//finalColor = 0;
	//all other point lights
	finalColor += AllPointLightsShading(i.screenPos.xy / i.screenPos.w, albedo.xyz, metallic, roughness, s.posWorld.xyz, normalWorld, viewDir, nDotV,
		mappingInfo,
		#ifdef USE_SSSENABLE_ON
				s1,
		#endif
		#ifdef USE_ANISOTROPY_ON
				anisotropy,
		#endif
		1);

	//test
	//return fixed4(finalColor,1);
	#endif
#endif

//屏幕sss计算
#ifdef _USE_SCREEN_SSS_ON
	ColorNumber4 subLayerColor = tex2D(_SSSTex, i.screenPos.xy / i.screenPos.w);
	ColorNumber diffuseAlpha = 1 - subLayerColor.a * _skinSubLayerFactor;
	//diffuseAlpha = (1 - subLayerColor.a)*(1 - _skinSubLayerFactor);

	finalColor *= _skinTopLayerColor.rgb;

	finalColor += _skinSubLayerColor.rgb * subLayerColor.rgb * (1 - diffuseAlpha);
#endif

#ifdef SHOW_AOMASKCOLOR_ON
	finalColor = 1;
#endif
//AO计算
#if defined(USE_AO_ON) && defined(_NORMALMAP)
	ColorNumber aoValue = s.ao;//normalColor.z;
	aoValue = lerp(lerp(1, aoValue, nDotV), aoValue, 2 * saturate(0.5 - aoValue));
	finalColor *= aoValue;
#endif

#ifdef SHOW_AOMASKCOLOR_ON
	return aoValue;
#endif

#ifdef	USE_GAMMA_SPACE_ON
#else
	finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
#endif

#ifdef USE_EMISSION_ON
	finalColor += _Emission * _EmissionFactor * (1 - s.emission)*albedo;
#endif
	

//#ifdef ST2_LAND
//#ifdef TYPE_SCENE
//	finalColor.rgb *= (1 - st2BlackFactor);
//#endif

#ifdef GRAY_ON
	float grey = dot(finalColor.rgb, ColorNumber3(0.22, 0.707, 0.071));
	finalColor.rgb = grey;
#endif

	UNITY_APPLY_FOG_COLOR(i.fogCoord / _FogFactor, finalColor.rgb, unity_FogColor);

	VectorNumber texAlpha = 1;
#ifdef	USE_ALPHA_BLEND_ON
	texAlpha = albedo.a;
#endif

#ifdef USE_ANITREE_ON
   //finalColor.rgb=lerp(_Fog,  finalColor, saturate(i.treeFog)) * (1 - st2BlackFactor) * _ColorMultiplier;
	finalColor.rgb = lerp(_Fog, finalColor, saturate(i.treeFog));
#endif

#ifdef TYPE_SCENE
	finalColor.rgb *= (1 - st2BlackFactor);
#endif
#ifdef USE_THINFILMREFLECT_ON

	ColorNumber4 _ThinFilmMaskColor = tex2D(_ThinFilmMask, uv);

	fixed3 reflectDir = normalize(reflect(-lightDir, normalWorld));
	fixed rdv = max(0, dot(reflectDir, viewDir));
	fixed ref_red = thinFilmReflectance(nDotH, 650.0, _FilmDepth, _IOR.r); //红光
	fixed ref_green = thinFilmReflectance(nDotH, 510.0, _FilmDepth, _IOR.g); //绿光
	fixed ref_blue = thinFilmReflectance(nDotH, 470.0, _FilmDepth, _IOR.b); //蓝光
	fixed4 tfi_rgb = fixed4(ref_red, ref_green, ref_blue, 1.0) * _ThinFilmColor;
	//fixed3 FinaThinFilm = tfi_rgb * nDotL * 0.4 + tfi_rgb * pow(rdv, 20);
	finalColor = lerp(finalColor, finalColor + 2*(tfi_rgb * nDotL * 0.4 + tfi_rgb * pow(rdv, 80)), _ThinFilmMaskColor);
	
#endif

	return ColorNumber4(finalColor, texAlpha);
}

//kajiya
ColorNumber4 kajiyaFragStandardBase(VertexOutputForwardBaseEx i) : COLOR
{
	PBR_BASE_INIT(gi)

	VectorNumber2 uv = i.tex.xy;

	VectorNumber3 normalWorld = s.normalWorld;
	
	VectorNumber3 binormalWorld = -normalize(i.tangentToWorldAndPackedData[1].xyz);
	
	//return ColorNumber4((binormalWorld + 1.0f) / 2.0f,1);

	//VectorNumber3 lightDir;
	//平行光
	//if(mainLight.dir.x == 0.0 && mainLight.dir.y == 0.0 && mainLight.dir.z == 0.0)
	//	lightDir = normalWorld;
	//else

	VectorNumber3 lightDir = gi.light.dir;

	ColorNumber3 finalColor = 0;

	VectorNumber3 viewDir = normalize(UnityWorldSpaceViewDir(s.posWorld));
	//VectorNumber nDotV = saturate(dot(normalWorld, viewDir));


	ColorNumber4 baseColor = tex2D(_MainTex, uv) * _Color;
	VectorNumber3 mask = tex2D(_MappingTex, uv).rgb;

	finalColor += KajiyaLighting(binormalWorld,normalWorld,lightDir,gi.light.color.rgb,viewDir,baseColor,mask);

	//sh and lightmaps
	//ambient += max(half3(0,0,0), ShadeSH9 (half4(normal, 1.0)));
	//finalColor += albedo * (1 - metallic) * max(half3(0,0,0), ShadeSH9 (half4(normalWorld, 1.0))) * _IndirectDiffuseFactor;

	finalColor += baseColor.rgb * gi.indirect.diffuse; //* _IndirectDiffuseFactor;

	//VectorNumber nDotL = saturate(dot(normalWorld, lightDir));

#ifdef NEED_ENV_ON
	VectorNumber3 refDir = normalize(reflect(-viewDir, normalWorld));
	ColorNumber4 envir = texCUBElod(_EnvCubeMap, VectorNumber4(refDir,0));
	envir.rgb *= envir.a;
	
	finalColor.rgb += envir.rgb;
#endif

#ifndef _FORCE_NO_USE_FORWARD_PLUS_RENDER_ON
	#ifdef _USE_FORWARD_PLUS_RENDER_ON
	finalColor += KajiyaAllDirectLightsShading(baseColor,mask,binormalWorld,normalWorld,viewDir);
	finalColor += KajiyaAllPointLightsShading(i.screenPos.xy / i.screenPos.w, baseColor,mask,s.posWorld,binormalWorld,normalWorld,viewDir);
	#endif
#endif

/*#if defined(USE_AO_ON) && defined(_NORMALMAP)
	ColorNumber aoValue = s.ao;//normalColor.z;
	aoValue = lerp(lerp(1, aoValue, nDotV), aoValue, 2 * saturate(0.5 - aoValue));
	finalColor *= aoValue;
#endif*/

	UNITY_APPLY_FOG_COLOR(i.fogCoord, finalColor.rgb, unity_FogColor * _FogFactor);
	return ColorNumber4(finalColor, 1);
}

//
#define PBR_ADD_INIT UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);\
UNITY_SETUP_INSTANCE_ID(i);\
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

//
#define PBR_ADD_INIT_MAIN_LIGHT(mainLight,posWorld) UnityLight mainLight;\
if (0.0 == _WorldSpaceLightPos0.w)\
	mainLight.dir = _WorldSpaceLightPos0.xyz;\
else\
	mainLight.dir = normalize(_WorldSpaceLightPos0.xyz - posWorld.xyz);\
UNITY_LIGHT_ATTENUATION(atten, i, posWorld);\
mainLight.color = _LightColor0.rgb * atten;\
	

//pbr frag standard add
ColorNumber4 pbrFragStandardAdd(VertexOutputForwardBaseAdd i) : COLOR
{
	PBR_ADD_INIT

	VectorNumber3 posWorld = IN_WORLDPOS(i);

	PBR_ADD_INIT_MAIN_LIGHT(mainLight, posWorld)

	VectorNumber3 lightDir = mainLight.dir;

	VectorNumber3 viewDir = normalize(UnityWorldSpaceViewDir(posWorld));
	VectorNumber3 halfDir = normalize(lightDir + viewDir);
	VectorNumber2 uv = i.tex.xy;

	VectorNumber3 binormal = normalize(i.tangentToWorldAndPackedData[1].xyz);
#ifdef _NORMALMAP
	VectorNumber3 tangent = normalize(i.tangentToWorldAndPackedData[0].xyz);
	ColorNumber4 normalColor = tex2D(_BumpMap, uv /** _BumpMap_ST.xy + _BumpMap_ST.zw*/);

#ifdef USE_FADE_TEX_ON
	normalColor = CalFadedNormal(normalColor,uv);
#endif

	normalColor.xy = normalColor.xy * 2 - 1;
	VectorNumber3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
	VectorNumber3 normal = normalize(normalize(i.tangentToWorldAndPackedData[2].xyz) + normalOffset);
#else
	VectorNumber3 normal = normalize(i.tangentToWorldAndPackedData[2].xyz);
#endif

	ColorNumber3 diffuse = 0;
	ColorNumber3 specular = 0;

	VectorNumber nDotH = saturate(dot(normal, halfDir));
	VectorNumber nDotV = saturate(dot(normal, viewDir));
	VectorNumber vDotH = saturate(dot(viewDir, halfDir));
	ColorNumber4 albedo = tex2D(_MainTex, uv /** _MainTex_ST.xy + _MainTex_ST.zw*/);

#ifdef USE_ALPHA_TEST_ON
	clip(albedo.a - _Cutoff);
#endif

	albedo *= _Color;

#ifdef USE_TATTOO_TEX_ON
	ColorNumber4 tattoo = tex2D(_TattooTex, (uv /** _MainTex_ST.xy + _MainTex_ST.zw*/)) * _Color;
	albedo.rgb = lerp(albedo.rgb, tattoo.rgb, tattoo.a * _TattooToggle);
#endif

#ifdef USE_FADE_TEX_ON

	albedo.rgb = CalFadedAlbedoColor(albedo.rgb,uv);

#endif

	ColorNumber3 m = tex2D(_MappingTex, uv /** _MappingTex_ST.xy + _MappingTex_ST.zw*/);
	VectorNumber nDotL = dot(normal, lightDir);

	nDotL = saturate(nDotL);
	ColorNumber s1 = 0;

	ColorNumber metallic = m.x;
	ColorNumber roughness = lerp(0.04, 1, saturate(m.z));
	albedo.rgb = albedo.rgb * albedo.rgb;
	//ColorNumber3 envShadow = lerp(_EnvShadowColor, 1, nDotL);
	diffuse += albedo * (1 - metallic) * ((nDotL + s1) * mainLight.color.rgb);
	ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
	float3 F = f_schlick(base, vDotH);
	float D = d_ggx(roughness, nDotH);
	float G = geometric(nDotV, nDotL, roughness);
	specular += D * F * G * (nDotL * mainLight.color.rgb );

	ColorNumber3 finalColor = (diffuse + specular);
#if defined(USE_AO_ON) && defined(_NORMALMAP)
	ColorNumber aoValue = normalColor.z;
	ColorNumber ao = lerp(lerp(1, aoValue, nDotV), aoValue, 2 * saturate(0.5 - aoValue));
	finalColor *= ao;
#endif

	finalColor = finalColor / (finalColor + 0.187f) * 1.035f;

#ifdef GRAY_ON
	float grey = dot(finalColor.rgb, ColorNumber3(0.22, 0.707, 0.071));
	finalColor.rgb = grey;
#endif

	return ColorNumber4(finalColor, 1);
}

//pbr frag land base
/*ColorNumber4 pbrFragLandBase(VertexOutputForwardBaseEx i) : COLOR
{
	PBR_BASE_INIT(gi)

	VectorNumber2 uv = i.tex.xy;

	VectorNumber3 normalWorld = s.normalWorld;

	//平行光
	//if(mainLight.dir.x == 0.0 && mainLight.dir.y == 0.0 && mainLight.dir.z == 0.0)
	//	lightDir = normalWorld;
	//else
	VectorNumber3 lightDir = -normalize(_IndirectLightDir.xyz);//gi.light.dir;

	ColorNumber3 finalColor = 0;

	VectorNumber3 viewDir = normalize(UnityWorldSpaceViewDir(s.posWorld));
	VectorNumber nDotV = saturate(dot(normalWorld, viewDir));
	ColorNumber4 albedo = tex2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw);
	albedo = albedo * albedo;
	ColorNumber3 mappingInfo = tex2D(_MappingTex, uv * _MappingTex_ST.xy + _MappingTex_ST.zw);
	ColorNumber roughness = lerp(0.04, 1, saturate(mappingInfo.z * _RoughnessFactor));
	ColorNumber metallic = saturate(mappingInfo.x * _MetalFactor);

	//#ifdef _NON_USE_PBR_GLOSSY_ON
	//	finalColor += DiffuseShading(albedo, metallic, (gi.indirect.diffuse * _IndirectDiffuseFactor),normalWorld, lightDir,1);
	//#else
	//	finalColor += PbrShading(albedo,metallic,roughness,(gi.indirect.diffuse * _IndirectDiffuseFactor),normalWorld,viewDir,nDotV,lightDir,1).rgb;
	//#endif

#ifndef _NON_USE_PBR_GLOSSY_ON
	finalColor += PbrShadingOnlySpecular(albedo, metallic, roughness, (gi.indirect.diffuse * _IndirectSpecFactor), normalWorld, viewDir, nDotV, lightDir).rgb;
#endif

	//sh and lightmaps
	finalColor += albedo * (1 - metallic) * gi.indirect.diffuse * _IndirectDiffuseFactor;


#ifdef NEED_ENV_ON		
	VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
	ColorNumber3 envShadow = lerp(_EnvShadowColor, 1, nDotL);

	VectorNumber3 refDir = normalize(reflect(-viewDir, normalWorld));
	ColorNumber4 envir = texCUBElod(_EnvCubeMap, VectorNumber4(refDir, int(roughness * 8)));
	envir.rgb *= envir.a;

	#if _HASMETAL_ON
	ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
	finalColor += lerp(0.6, 1, nDotL) * envir * envir_brdf(base, roughness, nDotV) * envShadow;
	#else
	finalColor += lerp(0.6, 1, nDotL) * envir * envir_brdf_nonmetal(roughness, nDotV) * envShadow;
	#endif
#endif

#ifndef _FORCE_NO_USE_FORWARD_PLUS_RENDER_ON
	#ifdef _USE_FORWARD_PLUS_RENDER_ON
	finalColor += AllDirectLightsShading(albedo.xyz, metallic, roughness, s.posWorld.xyz, normalWorld, viewDir, nDotV, 1);

	//test
	//finalColor = 0;
	//all other point lights
	finalColor += AllPointLightsShading(i.screenPos.xy / i.screenPos.w, albedo.xyz, metallic, roughness, s.posWorld.xyz, normalWorld, viewDir, nDotV, 1);

	//test
	//return fixed4(finalColor,1);
	#endif
#endif

#if defined(USE_AO_ON) && defined(_NORMALMAP)
	ColorNumber aoValue = s.ao;//normalColor.z;
	aoValue = lerp(lerp(1, aoValue, nDotV), aoValue, 2 * saturate(0.5 - aoValue));
	finalColor *= aoValue;
#endif

	finalColor = finalColor / (finalColor + 0.187f) * 1.035f;

	UNITY_APPLY_FOG_COLOR(i.fogCoord, finalColor.rgb, unity_FogColor);
	return ColorNumber4(finalColor, 1);
}*/

/*struct VertexOutputForwardBaseEx
{
	UNITY_POSITION(pos);
	VectorNumber4 tex : TEXCOORD0;
	VectorNumber3 eyeVec : TEXCOORD1;
	VectorNumber4 tangentToWorldAndPackedData[3]    : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
	VectorNumber4 ambientOrLightmapUV : TEXCOORD5;    // SH or Lightmap UV
	UNITY_SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)

		//#ifdef REALTIME_REFLECTION_ON
		//VectorNumber4 screenPos                 : TEXCOORD8;
		//#endif
		// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
		VectorNumber3 posWorld : TEXCOORD8;
#ifdef NEED_SCREENPOS
	VectorNumber4 screenPos : TEXCOORD9;
#endif
#else
#ifdef NEED_SCREENPOS
		VectorNumber4 screenPos : TEXCOORD8;
#endif
#endif

#ifdef USE_COMBINE_PARAMS
	VectorNumber fParamsIndex : TEXCOORD9;
#endif
#ifdef USE_ANITREE_ON
	VectorNumber treeFog : TEXCOORD10;
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
		UNITY_VERTEX_OUTPUT_STEREO
};


void sceneDiffuseVert(VertexInput v)
{
	UNITY_INITIALIZE_OUTPUT(Input, o);
	o.fog_1 = abs(v.normal);
	half4 pos = UnityObjectToClipPos(v.vertex);
	o.fog_1 = SimulateFog(pos);
}*/

//

#ifdef LMD_SCENE_DIFFUSE

sampler2D _EmissiveTex;
ColorNumber _Emissive;
ColorNumber _ColorMultiplier;
//ColorNumber st2BlackFactor;
ColorNumber _BloomIntension;
ColorNumber4 _Fog;

ColorNumber4 pbrFragSceneDiffuseBase(VertexOutputForwardBaseEx i) : COLOR
{
	//PBR_BASE_INIT(gi)

	FRAGMENT_SETUP(s)
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
	UnityLight mainLight = MainLight();

	VectorNumber3 viewDir = normalize(UnityWorldSpaceViewDir(s.posWorld));

#ifdef SHADOWS_SCREEN //如果没有这个宏，强制不进行衰减计算
	UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);
#else
	fixed atten = 1;
#endif

	//ColorNumber occlusion = _Occlusion;
	UnityGI gi = FragmentGI(s, 1.0, i.ambientOrLightmapUV, atten, mainLight);


	/*#ifdef ST2_LAND
		#ifdef LIGHTMAP_ON
		// Baked lightmaps
			#if !(defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN))
			gi.indirect.diffuse = gi.indirect.diffuse * atten;
			#endif
		#endif
	#endif*/

	/*#if defined(ST2_LAND) && defined(SHADOWS_SHADOWMASK)
			return float4(1,0,0,1);
	#endif

	#if defined(ST2_LAND) && !defined(LIGHTMAP_SHADOW_MIXING)
			return float4(0,1,0,1);
	#endif

	#if defined(ST2_LAND) && !defined(SHADOWS_SCREEN)
			return float4(0,0,1,1);
	#endif*/

	//test
	//gi.indirect.diffuse = float3(1,1,1);

	VectorNumber2 uv = i.tex.xy;

	ColorNumber4 c = tex2D(_MainTex, uv);
	ColorNumber4 emissive = tex2D(_EmissiveTex, uv);
	ColorNumber3 Albedo = c.rgb * _Color * _ColorMultiplier;
	ColorNumber4 Emission = emissive * _Emissive;

#ifdef _OUTPUT_BLOOM_DATA
	return step(0.99, c.a)*emissive*emissive.a*_BloomIntension;
#endif

	ColorNumber3 finalColor = 0;

	finalColor = lerp(Albedo, Albedo * gi.indirect.diffuse, _LightIntensity) + Emission;

	UNITY_APPLY_FOG_COLOR(i.fogCoord, finalColor.rgb, unity_FogColor * _Fog.rgb);

	finalColor *= (1 - st2BlackFactor);

	return ColorNumber4(finalColor, 1);
}
#endif


#endif

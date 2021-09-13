#ifndef PBR_COM_CGINC
#define PBR_COM_CGINC

#include "UnityCG.cginc"
uniform float4 _Color;
uniform sampler2D _MainTex;
uniform sampler2D _NormalMap;
uniform sampler2D _MappingTex;
uniform samplerCUBE _EnvCubeMap;
uniform float3 _EnvShadowColor;
uniform sampler2D _AnisoTex;
uniform float4 _Emission;
uniform float _EmissionFactor;

float _DynamicShadowSize;
float4x4 _DynamicShadowMatrix;
float4 _DynamicShadowParam;
sampler2D _DynamicShadowTexture;

uniform float _AnisoEnable;

float _Hardness;
float _Dissolve;
float _Width;
float _Start;
float _End;
float _Inversion;
sampler2D _DissolveTex;
sampler2D _MainTex02;
sampler2D _NormalMap02;
sampler2D _MappingTex02;
float4 _WidthColor;

#define _MinHeightAtten 0.7

struct A2v
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 texcoord : TEXCOORD0;
};

struct V2f
{
	float4 pos : SV_POSITION;
	float4 tex : TEXCOORD0;
	float3 posWorld : TEXCOORD1;
	float3 normalWorld : TEXCOORD2;
	float3 tangent : TEXCOORD3;
	float3 binormal : TEXCOORD4;
	float3 lightDir : TEXCOORD5;
#if defined(DYNAMIC_SHADOW_ENABLED)
	float4 shadowCoord : TEXCOORD6;
#endif
	float4 objPos:TEXCOORD7;
};

V2f vert(A2v v)
{
	V2f o;
	o.objPos = v.vertex;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.tex = float4(v.texcoord.xy, v.texcoord.xy);
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
	o.tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
	float vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
	o.binormal = cross(o.tangent, o.normalWorld) * vv * v.tangent.w;
	o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
#if defined(DYNAMIC_SHADOW_ENABLED)
	o.shadowCoord = mul(_DynamicShadowMatrix, float4(o.posWorld, 1));
	o.shadowCoord.xyz /= o.shadowCoord.w;
	o.shadowCoord.xy = o.shadowCoord.xy * 0.5 + 0.5;
	//o.shadowCoord.w = saturate(dot(o.normalWorld, o.lightDir));
	o.shadowCoord.w = 0;
#endif
	return o;
}

V2f vert_simple(A2v v)
{
	V2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.tex = v.texcoord;
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
	o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
	return o;
}

#define INV_PI 0.318309886f
#define PI 3.141592653f

float sg(float t, float a)
{
	float aa = a * a;
	return aa * aa * a;
	// return pow(a, t);
	//float k = t * 1.442695f + 1.089235f;
	//return exp2(k * a - k);
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
	//float k = roughness * roughness;
	//float k = 0.5 + roughness * 0.5;k *= k;
	float k = roughness * roughness * 0.5;
	float l = nDotL * (1.0 - k) + k;
	float v = nDotV * (1.0 - k) + k;
	return 0.25 / (l * v + 0.00001);
}

float3 envir_brdf(float3 specularColor, float roughness, float nDotV)
{
	const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
	float4 r = roughness * c0 + c1;
	float a004 = min(r.x * r.x, exp2(-9.28 * nDotV)) * r.x + r.y;
	float2 AB = float2(-1.04, 1.04) * a004 + r.zw;
	return specularColor * AB.x + AB.y;// * 0.35;
}

float3 envir_brdf_nonmetal(float roughness, float nDotV)
{
	const float2 c0 = { -1, -0.0275 };
	const float2 c1 = { 1, 0.0425 };
	float2 r = roughness * c0 + c1;
	return min(r.x * r.x, exp2(-9.28 * nDotV)) * r.x + r.y;
}

float4 texEnvLod(sampler2D env, float3 refDir, float roughness)
{
	float s = max(sign(refDir.z), 0);
	float a = s * 2 - 1;
	float2 ruv = refDir.xy / ((refDir.z + a) * a) * float2(0.25f, 0.25f) + 0.25f + 0.5f * s;
	float4 envir = tex2Dlod(env, float4(ruv.x, ruv.y, 0.0f, int(roughness * 8)));
	return envir;
}

//#if defined(SHADER_API_GLES) && !defined(SHADER_API_GLES30)
//#define TEX_CUBE_LOD texCUBE
//#else
//#define TEX_CUBE_LOD texCUBElod
//#endif

#define TEX_CUBE_LOD texCUBElod

half3 _SHEvalLinearL0L1 (half4 normal)
{
    half3 x;
    x.r = dot(half4(-0.27,1.1,-1.1,2.1),normal);
    x.g = dot(half4(-0.21,1,-0.96,1.5),normal);
    x.b = dot(half4(-0.16,0.97,-0.76,1.1),normal);
    return x;
}

half3 _SHEvalLinearL2 (half4 normal)
{
    half3 x1, x2;
    half4 vB = normal.xyzz * normal.yzzx;
    x1.r = dot(half4(-0.4,0.67,1,0.54),vB);
    x1.g = dot(half4(-0.27,-0.54,0.68,0.42),vB);
    x1.b = dot(half4(-0.19,-0.44,0.4,0.35),vB);
    half vC = normal.x*normal.x - normal.y*normal.y;
    x2 = half3(0.17,0.13,0.085) * vC;
    return x1 + x2;
}

half3 _ShadeSH9 (half4 normal)
{
    half3 res = _SHEvalLinearL0L1 (normal);
    res += _SHEvalLinearL2 (normal);

    res = max(res, half3(0.h, 0.h, 0.h));
    res = max(1.055h * pow(res, 0.416666667h) - 0.055h, 0.h);
    return res;
}

half3 _ShadeSHPerVertex (half3 normal, half3 ambient)
{
    #if UNITY_SAMPLE_FULL_SH_PER_PIXEL
        // Completely per-pixel
        // nothing to do here
    #elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        // Completely per-vertex
        ambient += max(half3(0,0,0), _ShadeSH9 (half4(normal, 1.0)));
    #else
        // L2 per-vertex, L0..L1 & gamma-correction per-pixel

        // NOTE: SH data is always in Linear AND calculation is split between vertex & pixel
        // Convert ambient to Linear and do final gamma-correction at the end (per-pixel)
        #ifdef UNITY_COLORSPACE_GAMMA
            ambient = GammaToLinearSpace (ambient);
        #endif
        ambient += _SHEvalLinearL2 (half4(normal, 1.0));     // no max since this is only L2 contribution
    #endif

    return ambient;
}

sampler2D _HQCharShadowmap,_HQCharShadowmapTransparent,_NoiseTex;
float4 _HQCharCameraParams;
float4x4 _HQCharCameraVP;
float _HQCharShadowmapSize;		
fixed _Bias;   			

#define OFFSET 1
#define _HQCSM_USE_NATIVE_DEPTH_ 1

float3 EncodeFloatRGB(float v)
{
    float3 kEncodeMul = float3(1.0,255.0,65025.0);
    float kEncodeBit = 1.0/255.0;
    float3 enc = kEncodeMul*v;
    enc = frac(enc);
    enc -= enc.yzz * kEncodeBit;
    return enc;
}

float DecodeFloatRGB(float3 enc)
{
    float3 kDecodeDot = float3(1.0,1/255.0,1/65025.0);
    return dot(enc,kDecodeDot);
}

float PCF(float2 xy, float sceneDepth, float bias)
{
    float shadow = 0.0;
    float2 texelSize = float2(1/_HQCharShadowmapSize,1/_HQCharShadowmapSize)*OFFSET;
    float4 shadowData = 0;
    float2 sampelDisk[4] = {float2(0,0),float2(0,1),float2(0.7,-0.7),float2(-0.7,-0.7)};
    for(int i = 0;i<4;++i)
    {
        float2 sampeluv = sampelDisk[i]*texelSize+xy;
        shadowData = tex2D(_HQCharShadowmapTransparent,sampeluv);
        #if defined(UNITY_REVERSED_Z) && UNITY_REVERSED_Z == 1
            #ifdef _HQCSM_USE_NATIVE_DEPTH_
            float depth = shadowData.x;
            #else
            float depth = DecodeFloatRGBA (shadowData);
            #endif
            float v = step(depth,sceneDepth-bias);
        #else
            #ifdef _HQCSM_USE_NATIVE_DEPTH_
                half depth = shadowData.x*2-1;
            #else
                half depth = DecodeFloatRGBA (shadowData)*2.0-1.0;
            #endif
            half v = step(sceneDepth,depth-bias);
        #endif
        v+=(1-shadowData.z);
        shadow+= v;
    }
    return (shadow*0.25);
}
 
float PCFForNoTrans(float2 xy, float sceneDepth, float bias)
{
    float shadow = 0.0;
    float2 texelSize = float2(1/_HQCharShadowmapSize,1/_HQCharShadowmapSize)*OFFSET;
    float4 shadowData = 0;
    float2 sampelDisk[4] = {float2(0,0),float2(0,1),float2(0.7,-0.7),float2(-0.7,-0.7)};
    for(int i = 0;i<4;++i)
    {
        float2 sampeluv = sampelDisk[i]*texelSize+xy;
        shadowData = tex2D(_HQCharShadowmap,sampeluv);
        #if defined(UNITY_REVERSED_Z) && UNITY_REVERSED_Z == 1
            #ifdef _HQCSM_USE_NATIVE_DEPTH_
            float depth = shadowData.x;
            #else
            float depth = DecodeFloatRGBA (shadowData);
            #endif
            float v = step(depth,sceneDepth+bias);
        #else
            #ifdef _HQCSM_USE_NATIVE_DEPTH_
                half depth = shadowData.x*2-1;
            #else
                half depth = DecodeFloatRGBA (shadowData)*2.0-1.0;
            #endif
            half v = step(sceneDepth,depth+bias);
        #endif
        shadow+= v;
    }
    return (shadow*0.25);
}

//smoothstep函数去掉平滑部分
inline float Smoothstep_Simple(fixed c,fixed minValue, fixed maxValue)
{
    c = (c - minValue)/(maxValue - minValue);
    c = saturate(c);
    return c ;
}

//溶解
inline float4 DoubleDissolveFunction(float2 uv,float y,float4 color01 ,float4 color02)
{
	float hardness = clamp(_Hardness,0.00001,999999);
	float dissolve = _Dissolve;
    dissolve *= (1 + _Width);
    fixed hardnessFactor = 2 - hardness;

	dissolve  = lerp(_Start,_End,dissolve);
	float4 dissolveTex = tex2D(_DissolveTex, uv);
	fixed dissolve01 = (dissolve- y) * hardnessFactor + dissolveTex;
	dissolve01 = Smoothstep_Simple((2-dissolve01),hardness,1);
	fixed dissolve02 = (dissolve- y - _Width) * hardnessFactor  + dissolveTex;
    dissolve02 = Smoothstep_Simple((2-dissolve02),hardness,1);

	float4 c = lerp(color02, lerp(_WidthColor,color01,dissolve01) , dissolve02);

	float4 c02 = lerp(color01, lerp(_WidthColor,color02,dissolve01) , dissolve02);
	
	return c*(1-_Inversion)+c02*_Inversion;
}


#endif
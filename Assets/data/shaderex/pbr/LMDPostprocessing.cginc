#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "LMDPbrInclude_ModelView.cginc"

#define NUMBER_HIGHT_ACCURACY

struct BloomVertexInput
{
	VectorNumber4 vertex : POSITION;
	VectorNumber3 normal : NORMAL;
	VectorNumber4 tangent : TANGENT;
	VectorNumber4 texcoord : TEXCOORD0;
};

struct VertexOutputBloom
{
	UNITY_POSITION(pos);
	VectorNumber4 tex : TEXCOORD0;
	VectorNumber3 posWorld : TEXCOORD1;
	VectorNumber3 normalWorld : TEXCOORD2;  
	VectorNumber3 tangent : TEXCOORD3;
	VectorNumber3 binormal : TEXCOORD4;
};

VertexOutputBloom bloomVert(BloomVertexInput v)
{
	VertexOutputBloom o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.tex = v.texcoord;
	o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.normalWorld  = normalize(UnityObjectToWorldNormal(v.normal));
	o.tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
	float vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
	o.binormal = cross(o.tangent, o.normalWorld) * vv * v.tangent.w;
	return o;
}

ColorNumber4 bloomFrag(VertexOutputBloom i) : COLOR
{
	VectorNumber3 tangent = normalize(i.tangent);
	VectorNumber3 binormal = normalize(i.binormal);

	ColorNumber4 albedo = tex2D(_MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw) * _Color;
	albedo = albedo * albedo;

	VectorNumber4 normalColor = tex2D(_BumpMap, i.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);
	normalColor.xy = normalColor.xy * 2 - 1;
	ColorNumber4 mappingInfo = tex2D(_MappingTex, i.tex.xy * _MappingTex_ST.xy + _MappingTex_ST.zw);
	ColorNumber metallic = mappingInfo.x;
	ColorNumber roughness = lerp(0.04, 1, saturate(mappingInfo.z));
	

	VectorNumber3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
	VectorNumber3 normalWorld = normalize(normalize(i.normalWorld) + normalOffset);

	VectorNumber3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
	VectorNumber3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
	VectorNumber3 halfDir = normalize(lightDir + viewDir);

	VectorNumber nDotH = saturate(dot(normalWorld, halfDir));
	VectorNumber vDotH = saturate(dot(viewDir, halfDir));
	VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
	VectorNumber nDotV = saturate(dot(normalWorld, viewDir));

	ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
	VectorNumber3 F = f_schlick(base, vDotH);
	VectorNumber D = d_ggx(roughness, nDotH);
	VectorNumber G = geometric(nDotV, nDotL, roughness);
	VectorNumber3 specular = D * F * G * nDotL ;
	float3 bloomColor = (1 - mappingInfo.w)*specular*0.1 + albedo * _Emission * _EmissionFactor * (1 - normalColor.w)*2.5;
	return float4(bloomColor, 1);
}
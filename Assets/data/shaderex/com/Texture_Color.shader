// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "自定义/贴图+颜色" {
Properties {
_MainTex ("Texture", 2D) = "white" {}
_AddTex("AddTexture", 2D) = "white" {}
_Color ("Main Color", Color) = (1,1,1,1)
}
SubShader
{
	Tags { "RenderType"="Opaque" }
	pass
	{
		CGPROGRAM
		#pragma multi_compile _ USE_ADD

		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		float4 _Color;
		float4 _MainTex_ST;

#ifdef USE_ADD
		sampler2D _AddTex;
#endif

		struct v2f
		{
			float4  pos : SV_POSITION; 
			float2  uv : TEXCOORD0; 
		};

		v2f vert (appdata_base v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			return o;
		} 

		float4 frag (v2f i) : COLOR
		{
#ifdef USE_ADD
			float4 tattoo = tex2D(_AddTex, i.uv);
			float4 albedo = tex2D(_MainTex, i.uv);

			albedo.rgb = lerp(albedo.rgb, tattoo.rgb, tattoo.a);

			return albedo * _Color;
#else
		    return tex2D(_MainTex, i.uv) * _Color;
#endif
		}

		ENDCG 
		}
	}
}
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "自定义/贴图+颜色+透明度+不写ZBuf" {
Properties {
_MainTex ("Texture", 2D) = "white" {}
_Color ("Main Color", Color) = (1,1,1,1)
}
SubShader
{
	Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

	Blend SrcAlpha OneMinusSrcAlpha
	ZWrite Off
	ZTest LEqual

	pass
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		float4 _Color;
		float4 _MainTex_ST;

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
		    return tex2D(_MainTex, i.uv) * _Color;
		}

		ENDCG 
		}
	}
}
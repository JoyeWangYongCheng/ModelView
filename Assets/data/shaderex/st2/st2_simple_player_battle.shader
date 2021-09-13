// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "streetball2/simple_model" {
Properties {
_MainTex ("Texture", 2D) = "white" {}
_Color ("Main Color", Color) = (1,1,1,1)
}
SubShader
{
	Tags { "RenderType"="Opaque" }
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
			fixed4 finalColor =  tex2D(_MainTex, i.uv) * _Color;
			//finalColor *= finalColor;
			//finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
		    return finalColor;
		}

		ENDCG 
		}
	}
}
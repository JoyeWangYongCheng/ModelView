// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "自定义/顶点+颜色" {
Properties {
_Color ("Main Color", Color) = (1,1,1,1)
}
SubShader
{
	Tags{"Queue" = "Transparent" "RenderType"="Transparent"}
	Blend SrcAlpha OneMinusSrcAlpha
	pass
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		float4 _Color;

		struct app
		{
			float4 pos : POSITION;
			float4 col : COLOR;
		};

		struct v2f
		{
			float4  pos : SV_POSITION; 
			float4  col : TEXCOORD0; 
		};

		v2f vert (app v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.pos);
			o.col = v.col;
			return o;
		} 

		float4 frag (v2f i) : COLOR
		{
		    return i.col * _Color;
		}

		ENDCG 
		}
	}
}
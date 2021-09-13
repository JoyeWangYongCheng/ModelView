// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "自定义/显示法线" {
Properties {
_MainTex ("Texture", 2D) = "white" {}
_ToonBaseTex ("ToonBase", CUBE) = "" { Texgen CubeNormal }
_ToonRampTex ("ToonRamp", 2D) = "white" {}
_ColorMain ("Main Color", Color) = (0.588,0.588,0.588,1)
_FloatGray ("Gray Float", Range(0,1)) = 0
}
SubShader
{
	Tags { "RenderType"="Opaque" }
	pass
	{
		Cull Off

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		float4 _MainTex_ST;
		sampler2D _MainTex;
		samplerCUBE _ToonBaseTex;
		sampler2D _ToonRampTex;
		float4 _ColorMain;
		float _FloatGray;

		struct appdata
		{
			float4 pos : POSITION;
			float2 uvw : TEXCOORD0;
			float3 nor : NORMAL;
		};

		struct v2f
		{
				float4 pos : POSITION;
				float2 mainUvw : TEXCOORD0;
				float3 cubeUvw : TEXCOORD1;
				float3 mnor : TEXCOORD2;
				float3 mpos : TEXCOORD3;
		};

		v2f vert (appdata v)
		{
				v2f o;
				o.pos = UnityObjectToClipPos (v.pos);
				o.mainUvw = TRANSFORM_TEX(v.uvw, _MainTex);
				o.cubeUvw = mul (UNITY_MATRIX_MV, float4(v.nor,0));
				o.mnor = mul (unity_ObjectToWorld, float4(v.nor,0));
				o.mpos = mul (unity_ObjectToWorld, v.pos);
				return o;
		}

		float4 frag (v2f i) : COLOR
		{
			float ramp = dot (normalize(_WorldSpaceCameraPos - i.mpos), i.mnor);
			float4 rampColor = tex2D(_ToonRampTex, float2(ramp, 0));

			float4 diffColor = _ColorMain * tex2D(_MainTex, i.mainUvw);
			float4 toneColor = texCUBE(_ToonBaseTex, i.cubeUvw);

			float4 comp = float4(2.0f * toneColor.rgb * diffColor.rgb, diffColor.a) * rampColor;
			float gray = comp.r * 0.299 + comp.g * 0.587 + comp.b * 0.114;

			return float4(i.mnor, 1);
		}

		ENDCG 
		}
	}
}
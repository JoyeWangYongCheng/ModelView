// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Toon/Basic" {
	Properties {
		_Color ("Main Color", Color) = (.5,.5,.5,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_ToonShade ("ToonShader Cubemap(RGB)", CUBE) = "" { Texgen CubeNormal }
		_GrayOrNot("Gray or not", Float) = 1
		_BattleOrNot("Battle or not", Float) = 1
	}


	SubShader {
		Tags { "RenderType"="Opaque" }
		Pass {
			Name "BASE"
			Cull Off
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			samplerCUBE _ToonShade;
			float4 _MainTex_ST;
			float4 _Color;
			float _GrayOrNot;

			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 cubenormal : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.cubenormal = mul (UNITY_MATRIX_MV, float4(v.normal,0));
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				half4 col = _Color * tex2D(_MainTex, i.texcoord);
				half gray = dot(col.rgb, float3(0.299, 0.587, 0.114));
				half4 gcol = float4(gray,gray,gray,1.0);	
				col = lerp(gcol, col, _GrayOrNot);

				half4 cube = texCUBE(_ToonShade, i.cubenormal);
				return half4(2.0f * cube.rgb * col.rgb, col.a);
			}
			ENDCG			
		}
	} 

	Fallback "VertexLit"
}

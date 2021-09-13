// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "自定义/Texture_UVAnim"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_XSpeed ("XSpeed",float) = 0
		_YSpeed ("YSpeed",float) = 0
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		
		LOD 100

		Pass
		{
		    Cull Off

			AlphaTest Greater .01
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _XSpeed;
			float _YSpeed;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 testuv = i.uv;
				testuv += float2(_XSpeed * _Time.y, _YSpeed * _Time.y);

				return tex2D(_MainTex, testuv);		
			}
			ENDCG
		}
	}
}

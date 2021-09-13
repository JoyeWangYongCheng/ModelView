Shader "streetball2/dissolve_blend"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_BorderColor("Border Color", Color) = (1,1,1,1)
		_BorderWidth("Border Width", Range(0, 0.2)) = 0.001
		_Threshold("Threshold", Range(0, 1)) = 0
	}

		SubShader
		{
			Tags{"Queue" = "Transparent" "RenderType" = "Transparent"}
			Blend SrcAlpha OneMinusSrcAlpha
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float4 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;

				sampler2D _NoiseTex;
				float4 _NoiseTex_ST;

				float _Threshold;
				float4 _BorderColor;
				float _BorderWidth;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
					o.uv.zw = TRANSFORM_TEX(v.uv, _NoiseTex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 color = tex2D(_MainTex, i.uv.xy);
					fixed4 noise = tex2D(_NoiseTex, i.uv.zw);
					noise.r = noise.r * (1 - _BorderWidth * 2) + _BorderWidth;
					fixed3 dissolveColor = lerp(_BorderColor.rgb, color.rgb, step(0, noise.r - _BorderWidth - _Threshold));
					color.rgb += dissolveColor;
					return color * step(_Threshold, noise.r);
				}
				ENDCG
			}
		}
}

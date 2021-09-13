Shader "streetball2/distortion/simple"
{
	Properties
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_NoiseTex("Noise Tex", 2D) = "black"{}
		_MaskTex("Mask Tex", 2D) = "white" {}
		_DistortionFactor("Distortion Factor", Range(0, 1.0)) = 0.02
		_TimeFactor("TimeFactor", Range(0.01, 2.0)) = 0.2
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
			};

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;

			sampler2D _MaskTex;

			float _DistortionFactor;
			float _TimeFactor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//half2 noiseUV = i.uv + half2(_SinTime.w, _SinTime.w) * _TimeFactor;
				//half2 noiseUV = i.uv + half2(_SinTime.w, _CosTime.w) * _TimeFactor;
				half2 noiseUV = i.uv + _Time.yy * _TimeFactor;

				half mask = tex2D(_MaskTex, i.uv).r;
				half2 offset = tex2D(_NoiseTex, noiseUV).rb * _DistortionFactor * mask;
				fixed4 col = tex2D(_MainTex, i.uv + offset) * _Color * i.color;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}

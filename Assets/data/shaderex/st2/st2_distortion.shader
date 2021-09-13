Shader "streetball2/distortion/screen"
{
	Properties 
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_NoiseTex("Noise Tex", 2D) = "white" {}
		_MaskTex("Mask Tex", 2D) = "white" {}
		_Factor ("Factor", Float) = 0.01
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

		Blend One Zero

		ZWrite Off
		Cull Back

		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float4 _Color;
			sampler2D _MaskTex;
			sampler2D _NoiseTex;
			float4 _MaskTex_ST;
			float4 _NoiseTex_ST;
			float _Factor;

			sampler2D st2ScreenCaptureTexture;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float4  pos : SV_POSITION; 
				float4  uvDistortion : TEXCOORD0;
				float4  uvMain : TEXCOORD1;
				fixed4 color : COLOR;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
#else
				float scale = 1.0;
#endif
				o.uvDistortion.xy = (float2(o.pos.x, o.pos.y * scale) + o.pos.w) * 0.5;
				o.uvDistortion.zw = o.pos.zw;
				o.uvMain.xy = TRANSFORM_TEX(v.texcoord, _MaskTex);
				o.uvMain.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				o.color = v.color;
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed4 uv = UNITY_PROJ_COORD(i.uvDistortion);
				fixed4 noise = tex2D(_NoiseTex, i.uvMain.zw);
				fixed2 offset = (noise.xy * 2 - 1) * tex2D(_MaskTex, i.uvMain.xy).r * _Factor;
				uv.xy = uv.xy + offset * i.color.a * _Color.a;
				fixed4 color = tex2Dproj(st2ScreenCaptureTexture, uv);
				return color * _Color * i.color;
			}

			ENDCG 
		}
	}
}
Shader "streetball2/scene_glass"
{
	Properties 
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		[Toggle] _ZwriteOn("ZWrite On", Int) = 0
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

		Blend One Zero, Zero Zero
		ZWrite [_ZwriteOn]
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
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;

			uniform float st2BlackFactor;
			sampler2D st2ScreenCaptureTexture;
			
			struct v2f
			{
				float4  pos : SV_POSITION; 
				float4  uv : TEXCOORD0; 
				float4  dpos : TEXCOORD1;
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				o.dpos = o.pos;
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed4 color = tex2D(_MainTex, i.uv) * _Color;
#if UNITY_UV_STARTS_AT_TOP
				fixed scale = -1.0;
#else
				fixed scale = 1.0;
#endif
				fixed4 noise = tex2D(_NoiseTex, i.uv.zw);
				fixed2 offset;
				offset.x = (noise.x * 2 - 1) * 0.1 + 1;
				offset.y = (noise.x * 2 - 1) * 0.05 + 1;
				float4 duv;
				duv.xy = (float2(i.dpos.x * offset.x, (i.dpos.y * offset.y) * scale ) + i.dpos.w) * 0.5;
				duv.zw = i.pos.zw;
				fixed4 uv = UNITY_PROJ_COORD(duv);
				fixed4 backGroundColor = tex2Dproj(st2ScreenCaptureTexture, uv);
				return fixed4(lerp(color.rgb, backGroundColor.rgb, (1 - color.a) * 0.5), color.a) * (1 - st2BlackFactor);
			}

			ENDCG 
		}
	}
}
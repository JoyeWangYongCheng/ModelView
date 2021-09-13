Shader "streetball2/distortion/sphere"
{
	Properties 
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white" {}
		_DistortionTex ("DistortionTex", 2D) = "white" {}
		_NoiseTex ("NoiseTex", 2D) = "white" {}
		_Factor ("Factor", Float) = 0.01
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType"="Opaque"}

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
			sampler2D _MainTex;
			sampler2D _DistortionTex;
			sampler2D _NoiseTex;
			float4 _MainTex_ST;
			float4 _NoiseTex_ST;
			float _Factor;

			sampler2D st2ScreenCaptureTexture;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float4  pos : SV_POSITION; 
				float4  uvDistortion : TEXCOORD0;
				float4  uvMain : TEXCOORD1;
				float3  normalWorld : TEXCOORD2;
				float3  posWorld : TEXCOORD3;
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
				o.uvMain.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvMain.xy.x += _Time.y;
				o.uvMain.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
				o.color = v.color;
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed4 uv = UNITY_PROJ_COORD(i.uvDistortion);
				fixed4 noise = tex2D(_NoiseTex, i.uvMain.zw);
				uv.xy = uv.xy + (noise.xy * 2 - 1) * tex2D(_DistortionTex, i.uvMain.xy).r * _Factor;
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
				fixed3 normal = normalize(i.normalWorld);
				fixed vdn = max(dot(normal, viewDir), 0);
				fixed4 color = tex2Dproj(st2ScreenCaptureTexture, uv);
				color = color + (1 - vdn) * 0.2 * tex2D(_MainTex, i.uvMain.xy) * fixed4(0, 0, 1, 1);
				return color * _Color * i.color;
			}

			ENDCG 
		}
	}
}
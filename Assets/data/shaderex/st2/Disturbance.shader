Shader "TA_Test/UIEffect/Disturbance"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("NoiseTex",2D) = "white" {}
		_MaskTex("MaskTex",2D) = "white"{}
		_Speed("speed",float)=1
		_NoiseIntensity("NoiseIntensity",Range(0,10)) = 1
	}
	SubShader
	{
		// No culling or depth
		// Cull Off ZWrite Off ZTest Always
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
        }

        LOD 100
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

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
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float2 noise_uv:TEXCOORD1;
			};

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _NoiseTex;
float4 _NoiseTex_ST;
sampler2D _MaskTex;
float4 _MaskTex_ST;
float _Speed;
float _NoiseIntensity;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.noise_uv = TRANSFORM_TEX(v.uv,_NoiseTex);
				o.noise_uv.x += _Time.x*_Speed;
				o.noise_uv.y += _Time.z*_Speed;
				return o;
			}
			
			

			fixed4 frag (v2f i) : SV_Target
			{
				
				fixed4 noiseCol = tex2D(_NoiseTex,i.noise_uv);
				half2 noiseuv = {noiseCol.r,noiseCol.g};
				//颜色值是（0,1），而扰动需要（-1,1）
				noiseuv = (noiseuv-0.5)*2;

				fixed4 maskTex = tex2D(_MaskTex,i.uv);
				half maskuv = maskTex.r;
				fixed4 col = tex2D(_MainTex,i.uv+(noiseuv*0.01*_NoiseIntensity)*maskuv);

				return col;
			}
			ENDCG
		}
	}
}

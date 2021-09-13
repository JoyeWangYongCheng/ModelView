Shader "TA_Test/Disturbance"
{
	Properties
	{
		_MainColor("主颜色",Color)=(1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_MainTransparent("主透明度",Range(0,1))=1
		_NoiseColor("噪波颜色",Color)=(1,1,1,1)
		_NoiseTex("噪波图",2D)="white"{}
		_DistortTimeFactor("速度",vector)=(0,0,0,0)
		_DistortStrength("幅度",Range(0,1))=0.2
	}
	SubShader
	{
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
		LOD 100


//         GrabPass
// 		{
// //此处给出一个抓屏贴图的名称，抓屏的贴图就可以通过这张贴图来获取，而且每一帧不管有多个物体使用了该shader，只会有一个进行抓屏操作
// 			//如果此处为空，则默认抓屏到_GrabTexture中，但是据说每个用了这个shader的都会进行一次抓屏！

// 			"_GrabTempTex"
// 		}
		Pass
		{
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			sampler2D _GrabTempTex;
			fixed4 _GrabTempTex_ST;
			sampler2D _NoiseTex;
			fixed4 _NoiseTex_ST;
            fixed4 _DistortTimeFactor;
            fixed _DistortStrength;
			sampler2D _MainTex;
			fixed4 _MainTex_ST;			
            fixed _MainTransparent;
			fixed4 _MainColor;
			fixed4 _NoiseColor;


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD1;
				float4 grabPos:TEXCOORD0;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.grabPos = ComputeGrabScreenPos(o.pos);
				o.uv = TRANSFORM_TEX(v.uv,_NoiseTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
//首先采样噪声图，采样的uv值随着时间连续变换，而输出一个噪声图中的随机值，乘以一个扭曲快慢系数
                fixed4 mainTex = tex2D(_MainTex,i.uv);
				fixed2 offset = fixed2((i.uv.x + mainTex.r)-_Time.x * _DistortTimeFactor.x,i.uv.y - _Time.x * _DistortTimeFactor.y)*_DistortStrength;
				// return offset;
			//用采样的噪声图输出作为下次采样Grab图的偏移值，此处乘以一个扭曲力度的系数
				// i.grabPos.xy -= noiseTex.xy * _DistortStrength;

				// fixed4 color = tex2Dproj(_GrabTempTex,i.grabPos);
				fixed4 noiseTex = tex2D(_NoiseTex,offset);
				float3 emissive = (mainTex.rgb*_MainColor.rgb)+(noiseTex.rgb*_NoiseColor.rgb);
				return fixed4(emissive.rgb,(mainTex.a+_NoiseColor.a)*(noiseTex.a+_MainColor.a)*_MainTransparent);
			}
			ENDCG
		}
	}
}

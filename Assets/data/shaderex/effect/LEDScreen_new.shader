Shader "st2/LEDScreen"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MaskTex("Mask Texture",2D) = "white"{}
		// _Xcount("x count",int)=1
		// _Ycount("y count",int)=1
		_Offset("Grid Offset",vector)=(0,0,0,0)		
	}
	SubShader
	{
		// No culling or depth
		// Cull Off ZWrite Off ZTest Always
        Tags
        {
            "Queue"="Geometry"

            "RenderType"="Opaque"
        }

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
				float2 maskUV:TEXCOORD1;
				float4 vertex : SV_POSITION;
			};
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _MaskTex;
			float4 _MaskTex_ST;
			// int _Xcount;
			// int _Ycount;
			float4 _Offset;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);

#if UNITY_UV_STARTS_AT_TOP	
				o.uv.y= 1-o.uv.y;
#endif			
				o.maskUV = TRANSFORM_TEX(v.uv,_MaskTex);
				return o;
			}
			
			

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 mask = tex2D(_MaskTex,i.maskUV);
				float2 uv01 = float2(i.maskUV+_Offset.xy);
				fixed4 mask01 = tex2D(_MaskTex,uv01);
				// return mask01.r;
				// return mask.a*(1-mask.r);
				// return lerp(0,col*(1-mask),mask.a ) ;
				return col*(1-mask.r)*mask.a*(1-mask01.r*_Offset.z);
			}
			ENDCG
		}
	}
}

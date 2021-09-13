Shader "TA_Test/SSSskin01"
{
	Properties
	{
      _MatCap ("Matcap", 2D) = "white"{}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
 
		Pass
		{
			Tags {"LightMode"="Always"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

 			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 TtoV0:TEXCOORD1;
				float3 TtoV1:TEXCOORD2;
			};


			sampler2D _MatCap;

			// sampler2D _GlobalMatcap;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				// //将法线从模型空间转换到视觉空间，以便映射Matcap采样贴图
                // o.NtoV.x = mul(UNITY_MATRIX_IT_MV[0],v.normal);
				// o.NtoV.y = mul(UNITY_MATRIX_IT_MV[1],v.normal);
				//乘以逆转置矩阵将normal变换到视空间
				float3 viewnormal = mul(UNITY_MATRIX_IT_MV, v.normal);
				viewnormal = normalize(viewnormal);
				float3 viewPos = UnityObjectToViewPos(v.vertex);
				float3 r = reflect(viewPos, viewnormal);
				float m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
				o.uv = r.xy / m + 0.5;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                fixed4 mat = tex2D(_MatCap, i.uv);
				return mat;
			}
			ENDCG
		}
	}
}

Shader "TA_Test/GlowObject"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_Outline("OutLine", Float) = 2
	}
	
	SubShader
	{
		Tags{ "RenderType"="Transparent" "Queue"="Transparent" }  
		ZWrite OFF

		Pass
		{
			Blend One One
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			fixed4 _Color;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = _Color;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}

			ENDCG
		}

		Pass
		{
			CULL OFF
			ZTest OFF
			COLORMASK 0

			Stencil
			{
				Ref 1
				Comp NotEqual
				Pass Replace
				ReadMask 1
				WriteMask 1
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			float _Outline;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);  
				float2 offset = TransformViewToProjection(norm.xy);  
				o.vertex.xy += normalize(offset) * o.vertex.z * _Outline;  

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				return 1;
			}

			ENDCG
		}
	}
}

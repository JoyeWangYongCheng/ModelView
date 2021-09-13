Shader "Debug/BlockScopeSphere"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Main Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		ZTest Always

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
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float4 localPos : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;

			float3 _ForwardDir;
			float3 _Center;
			float _Radius;
			float _Angle;
			float _MaxHeight;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.localPos = v.vertex;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 delta = i.localPos;
				float3 dirXZ = float3(delta.x, 0, delta.z);
				float d = dot(normalize(dirXZ), float3(0,0,1));
				float threshold = cos(radians(_Angle));

				if (i.worldPos.y > _MaxHeight)
				{
					discard;
				}

				if (d >= threshold)
				{
					return _Color;
				}
				else
				{
					return fixed4(0, 0, 0, 0);
				}
			}
			
			ENDCG
		}
	}
}

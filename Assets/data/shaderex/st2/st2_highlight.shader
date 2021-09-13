Shader "streetball2/highlight"
{
	Properties
	{
		_NoiseTex("Noise", 2D) = "white" { }
		_Outline("Outline width", Range(.002, 0.03)) = .005
		_Color("Main Color", Color) = (1,1,1,1)
	}
		SubShader
		{
			Tags { "LightMode" = "ForwardBase" }

			Blend One One
			Cull Back
			ZWrite Off

			pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				sampler2D _NoiseTex;
				float4 _Color;
				float _Outline;

				struct v2f
				{
					float4  pos : SV_POSITION;
					float3  normalWorld : TEXCOORD0;
					float3  posWorld : TEXCOORD1;
				};

				v2f vert(appdata_full v)
				{
					v2f o;
					o.posWorld = mul(unity_ObjectToWorld, v.vertex);
					o.normalWorld = normalize(UnityObjectToWorldNormal(v.normal));

					float4 view_vertex = mul(UNITY_MATRIX_MV, v.vertex);
					float3 view_normal = mul(UNITY_MATRIX_IT_MV, fixed4(v.normal, 1)).xyz;
					view_vertex.xyz += normalize(view_normal) * _Outline;
					o.pos = mul(UNITY_MATRIX_P, view_vertex);
					return o;
				}

				float4 frag(v2f i) : COLOR
				{
					fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
					fixed3 normal = normalize(i.normalWorld);
					fixed vdn = max(dot(normal, viewDir), 0);
					fixed a = (1 - vdn) * _Color.a * tex2D(_NoiseTex, vdn).a;
					return fixed4(_Color.rgb * a, 1);
				}

				ENDCG
			}
		}
}
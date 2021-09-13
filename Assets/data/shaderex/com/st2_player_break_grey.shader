Shader "streetball2/player_break_grey"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		_MaskTex("Mask Texture", 2D) = "white" {}
		_Color("Main Color", Color) = (1,1,1,1)
		_Direction("Direction", Vector) = (0,0,1,1)
	}
		SubShader
		{
			Tags{"Queue" = "Transparent" "RenderType" = "Transparent"}

			Blend SrcAlpha OneMinusSrcAlpha
			Cull Front
			ZWrite Off

			pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				sampler2D _MainTex;
				sampler2D _MaskTex;

				float4 _Direction;
				float4 _Color;

				struct v2f
				{
					float4  pos : SV_POSITION;
					float4  uv : TEXCOORD0;
					float3  normal : TEXCOORD1;
					float4  posWorld : TEXCOORD2;
				};

				v2f vert(appdata_full v)
				{
					v2f o;
					o.uv.xy = v.texcoord;
					o.normal = normalize(UnityObjectToWorldNormal(v.normal));
					float3 posWorld = mul(unity_ObjectToWorld, v.vertex);
					float3 direction = normalize(-_Direction);
					o.uv.zw = float2(0.1, posWorld.y / 2);
					float dND = dot(o.normal, direction);
					float alpha = 1;
					if (dND > 0 && dND < 0.1)
					{
						posWorld = posWorld + direction * _Direction.a;
						o.uv.z = _Direction.a / 0.01;
						alpha = 0;
					}
					o.posWorld = float4(posWorld, alpha);
					o.pos = mul(UNITY_MATRIX_VP, fixed4(o.posWorld.xyz, 1));
					return o;
				}

				float4 frag(v2f i) : COLOR
				{
					fixed3 color = tex2D(_MainTex, i.uv.xy).rgb;
					color *= 1.5;
					fixed mask = tex2D(_MaskTex, i.uv.zw).a * i.posWorld.w;
					fixed gray = dot(color.rgb, fixed3(0.299, 0.587, 0.114));
					return fixed4(gray, gray, gray, mask);
				}

				ENDCG
			}
		}
}

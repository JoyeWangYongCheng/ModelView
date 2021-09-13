﻿
	

Shader "LMD/Scene/AlphaBlendShadow"
{
		Properties{
			_Color("Color Tint", Color) = (1, 1, 1, 1)
			_MainTex("Main Tex", 2D) = "white" {}
			_AlphaScale("Alpha Scale", Range(0, 1)) = 1
		}
			SubShader{
				Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

				Pass {
				//	Tags { "LightMode" = "ForwardBase" }

					ZWrite Off
					Blend SrcAlpha OneMinusSrcAlpha

					CGPROGRAM

				#include "Lighting.cginc"
			//#include "AutoLight.cginc"

					#pragma vertex vert
					#pragma fragment frag

					

					fixed4 _Color;
					sampler2D _MainTex;
					float4 _MainTex_ST;
					fixed _AlphaScale;

					struct a2v {
						float4 vertex : POSITION;
					
						float4 texcoord : TEXCOORD0;
					};

					struct v2f {
						float4 pos : SV_POSITION;
						float3 worldNormal : TEXCOORD0;
						float3 worldPos : TEXCOORD1;
						float2 uv : TEXCOORD2;
						
					};

					v2f vert(a2v v) {
						v2f o;
						o.pos = UnityObjectToClipPos(v.vertex);

					

						o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

						o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

						return o;
					}

					fixed4 frag(v2f i) : SV_Target {
					
					

						fixed4 texColor = tex2D(_MainTex, i.uv);

						fixed3 albedo = texColor.rgb * _Color.rgb;

					

					

						return fixed4(albedo, texColor.a * _AlphaScale);
					}

					ENDCG
				}
			}
			
						// Or  force to apply shadow
					//	FallBack "VertexLit"
	}

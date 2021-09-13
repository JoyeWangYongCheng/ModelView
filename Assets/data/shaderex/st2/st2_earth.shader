//===========================================================
// StreetBall2-Earth-Shader
// Author: Xia Liqiang
// Version : 1.0.0
// Date : 2018.10.10
//===========================================================
Shader "streetball2/earth"
{
	Properties
	{
		_LightDir ("Light Direction", Vector) = (0.2,1,-0.4,0)
		_LightColor("Light Main Color", Color) = (0.670588, 0.55294, 0.768627, 1.0)
		_BorderColor("Border Main Color", Color) = (0, 0, 1, 1.0)
		_DiffTex("Diffuse Texture", 2D) = "white" {}
		_Gloss("Gloss",Range(8.0, 256)) = 16
	}

	Subshader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			uniform sampler2D _DiffTex;
			uniform fixed4 _LightDir;
			uniform fixed4 _LightColor;
			uniform fixed4 _BorderColor;
			uniform fixed _Gloss;

			struct A2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct V2f
			{
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
				float3 posWorld : TEXCOORD1;
				float3 normalWorld : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
			};

			V2f vert(A2v v)
			{
				V2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.tex = v.texcoord;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
				o.lightDir = normalize(mul(unity_ObjectToWorld, fixed4(_LightDir.xyz, 0)));
				return o;
			}

			fixed4 frag(V2f i) : COLOR
			{
				fixed4 texColor = tex2D(_DiffTex, i.tex.xy);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
				fixed borderFactor = 1 - dot(i.normalWorld, viewDir);
				borderFactor = borderFactor * borderFactor;
				fixed3 halfDir = normalize(i.lightDir + viewDir);
				fixed lightFactor = max(0, dot(halfDir, i.normalWorld));
				lightFactor = pow(lightFactor, _Gloss);
				fixed texFactor = (dot(i.normalWorld, i.lightDir) * 0.35 + 0.65);
				fixed4 result = texColor * texFactor + _BorderColor * borderFactor + _LightColor * lightFactor;
				result.a = 1;
				return result;
			}

			ENDCG
		}
	}
}
//===========================================================
// StreetBall2-PBR-Shader
// Author: Xia Liqiang
// Version : 1.0.0
// Date : 2018.3.12
//===========================================================
Shader "streetball2/model_alpha"
{
	Properties
	{
		_LightDir ("Light Direction", Vector) = (0.2,1,-0.4,0)
		_LightColor("Light Main Color", Color) = (0.62745, 0.62745, 0.62745, 1.0)
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "grey" {}
		_MappingTex("Mapping Texture", 2D) = "grey" {}
		[Toggle] _HasMetal ("Has Metal", Float) = 1
		[Toggle] _SSSEnable ("SSS Enable", Float) = 0 
		_EnvCubeMap("Enviroument Convolution Cubemap", Cube) = ""{}
		_EnvShadowColor("Enviroument Shadow Color", Color) = (0.5, 0.5, 0.5, 1.0)
		[Toggle] _AnisoEnable ("Aniso Enable", Float) = 0
		_AnisoTex("Aniso Texture", 2D) = "white" {}
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
			//#pragma shader_feature _HASMETAL_ON
			//#pragma shader_feature _SSSENABLE_ON
			//#pragma shader_feature _ANISOENABLE_ON
			//#pragma multi_compile __ DYNAMIC_SHADOW_ENABLED
			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform sampler2D _NormalMap;
			uniform sampler2D _MappingTex;
			uniform samplerCUBE _EnvCubeMap;
			uniform fixed3 _EnvShadowColor;
			uniform sampler2D _AnisoTex;
			uniform sampler2D _DecalTex;
			uniform fixed4 _LightDir;

			float _DynamicShadowSize;
			float4x4 _DynamicShadowMatrix;
			float4 _DynamicShadowParam;
			sampler2D _DynamicShadowTexture;
			float3 _LightColor;

			struct A2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct V2f
			{
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
				float3 posWorld : TEXCOORD1;
				float3 normalWorld : TEXCOORD2;
				float3 tangent : TEXCOORD3;
				float3 binormal : TEXCOORD4;
				float3 lightDir : TEXCOORD5;
			#ifdef DYNAMIC_SHADOW_ENABLED
				float4 shadowCoord : TEXCOORD6;
			#endif
			};

			V2f vert(A2v v)
			{
				V2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.tex = v.texcoord;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
				o.tangent  = normalize(UnityObjectToWorldDir(v.tangent.xyz));
				float vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
				o.binormal = cross(o.tangent, o.normalWorld) * vv * v.tangent.w;
				o.lightDir = normalize(_LightDir);
				return o;
			}

			fixed4 frag(V2f i) : COLOR
			{
				fixed4 texColor = tex2D(_MainTex, i.tex.xy);
				return texColor * (dot(i.normalWorld, fixed3(0, 1, 0)) * 0.5 + 0.5) * 1;
			}

			ENDCG
		}
	}
}
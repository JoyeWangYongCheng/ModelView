// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
/*
Shader "streetball2/scene_recorder" {
	Properties{
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200

		CGPROGRAM

		#pragma surface surf Scene

		uniform float st2BlackFactor;
		
		inline void LightingScene_GI(
			SurfaceOutput s,
			UnityGIInput data,
			inout UnityGI gi)
		{
			gi = UnityGlobalIllumination(data, 1.0, s.Normal);
		}


		inline fixed4 UnitySceneLight(SurfaceOutput s, UnityLight light)
		{
			fixed4 c;
			c.rgb = (s.Albedo * 0.35 + ( s.Albedo * light.color * 0.65)) * (1 - st2BlackFactor);
			c.a = s.Alpha;
			return c;
		}

		inline fixed4 LightingScene(SurfaceOutput s, UnityGI gi)
		{
			fixed4 c;
			c = UnitySceneLight(s, gi.light);
			return c;
		}

		sampler2D _MainTex;
		fixed4 _Color;
		

		struct Input {
			float2 uv_MainTex;
		};

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	}

		Fallback "Legacy Shaders/VertexLit"
}
*/
Shader "streetball2/scene_recorder"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_Shadow("ShadowColor",color) = (0.44,0.54,0.67,1)
}
	SubShader
	{
		Tags {"RenderType" = "Opaque"}
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			#pragma vertex vertexMain
			#pragma fragment fragmentMain

			uniform float st2BlackFactor;

			fixed4 _Shadow;
			sampler2D _MainTex;

			struct VertexToFragment
			{
				float4 pos         : SV_POSITION;
				half4 uv          : TEXCOORD0;
				SHADOW_COORDS(1)
			};

			VertexToFragment vertexMain(appdata_full v)
			{
				VertexToFragment result = (VertexToFragment)0;
				result.pos = UnityObjectToClipPos(v.vertex);
				result.uv.xy = v.texcoord.xy;
				TRANSFER_SHADOW(result)
				return result;
			}

			fixed4 fragmentMain(VertexToFragment i) : COLOR0
			{
				float attenuation = SHADOW_ATTENUATION(i);
				float4 mainColor = tex2D(_MainTex, i.uv.xy);
				return lerp(mainColor * _Shadow, mainColor, attenuation) * (1 - st2BlackFactor);
			}

			ENDCG
		}

		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
			#include "UnityCG.cginc"

			struct v2f {
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}
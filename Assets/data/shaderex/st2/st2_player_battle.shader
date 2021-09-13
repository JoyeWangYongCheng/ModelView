//===========================================================
// StreetBall2-PBR-Shader
// Author: Xia Liqiang
// Version : 1.0.0
// Date : 2018.3.12
//===========================================================
Shader "streetball2/model_battle"
{
	Properties
	{
		_Color("Main Color", Color) = (1, 1, 1, 1)
		_LightDir("Light Direction", Vector) = (0.2,1,-0.4,0)
		_LightColor("Light Main Color", Color) = (0.670588, 0.55294, 0.768627, 1.0)
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "grey" {}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 150

		CGPROGRAM
		#pragma surface surf Battle noforwardadd

		inline fixed4 LightingBattle(SurfaceOutput s, UnityGI gi)
		{
			fixed4 c = 0;

			#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
				c.rgb += s.Albedo * gi.indirect.diffuse;
			#endif

			return c;
		}

		inline void LightingBattle_GI(
			SurfaceOutput s,
			UnityGIInput data,
			inout UnityGI gi)
		{
			gi = UnityGlobalIllumination(data, 1.0, s.Normal);
		}

		sampler2D _MainTex;
		float4 _Color;

		struct Input {
			float2 uv_MainTex;
		};

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color;
			o.Alpha = c.a;
		}
		ENDCG
	}

		//Fallback "Mobile/VertexLit"
}
Shader "streetball2/scene_lightingmap"
{
	Properties
	{
		_Color("Main Color", Color) = (1, 1, 1, 1)
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
	}

	SubShader
	{
		Tags { "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
		LOD 150

		CGPROGRAM
		#pragma surface surf Battle noforwardadd alphatest:_Cutoff

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
		uniform float st2BlackFactor;

		struct Input {
			float2 uv_MainTex;
		};

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color * (1 - st2BlackFactor);
			o.Alpha = c.a;
		}
		ENDCG
	}

		//Fallback "Mobile/VertexLit"
}
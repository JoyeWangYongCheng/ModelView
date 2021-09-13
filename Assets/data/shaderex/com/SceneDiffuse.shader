
Shader "LMD/Scene/Diffuse"
{
	Properties
	{
		_Color ("Main Color", Color) = ( 1, 1, 1, 1)
	    _ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex ("Texture", 2D) = "white" {}
		_LightIntensity("Light Intensity",Range(0,1))=1
		_Fog("Fog Color", Color) = (1,1,1,1)
		_Factor("Factor", Range(0, 0.05)) = 0
		_EmissiveTex("Emissive Texture",2D)="black"{}
		_Emissive("Emissive",Range(0,1))=0
		_BloomIntension("Bloom Intension",Range(0,1))=0
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 150

		CGPROGRAM
		#pragma surface surf Battle noforwardadd vertex:vert finalcolor:Fog
        #pragma multi_compile __ _OUTPUT_BLOOM_DATA

		sampler2D _MainTex;
		half4 _Color;
		half _ColorMultiplier;
		half _LightIntensity;
		uniform half st2BlackFactor;
		half4 _Fog;
		half _Factor;
        half _Emissive;
		sampler2D _EmissiveTex;
		float _BloomIntension;
		struct Input 
		{
			half2 uv_MainTex;
			half fog;
		};

		half SimulateFog(half4 pos)
		{
#if defined(UNITY_REVERSED_Z)
	#if UNITY_REVERSED_Z == 1
			half z = max(((1.0 - (pos.z) / _ProjectionParams.y)*_ProjectionParams.z), 0);
	#else
			half z = max(-(pos.z), 0);
	#endif
#elif UNITY_UV_STARTS_AT_TOP
			half z = pos.z;
#else
			half z = pos.z;
#endif
			half fogFactor = exp2(-_Factor * z);
			fogFactor = clamp(fogFactor, 0.0, 1.0);
			return fogFactor;
		}

		inline half4 LightingBattle(SurfaceOutput s, UnityGI gi)
		{
			half4 c = 0;
			#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
				c.rgb += lerp(s.Albedo, s.Albedo * gi.indirect.diffuse, _LightIntensity);
			#else
				c.rgb = s.Albedo.rgb;
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

		inline void Fog(Input IN, SurfaceOutput o, inout fixed4 color)
        {
            color.rgb = lerp(_Fog, color, saturate(IN.fog)) * (1 - st2BlackFactor);
			half4 c = tex2D(_MainTex, IN.uv_MainTex);
			half4 emissive= tex2D(_EmissiveTex,IN.uv_MainTex);
			#ifdef _OUTPUT_BLOOM_DATA
            color = step(0.99,c.a)*emissive*emissive.a*_BloomIntension;
		    #endif
        }
		
		void vert (inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.fog = abs(v.normal);
			half4 pos = UnityObjectToClipPos(v.vertex);
			o.fog = SimulateFog(pos);
		}	

		void surf(Input IN, inout SurfaceOutput o) {
			half4 c = tex2D(_MainTex, IN.uv_MainTex);
			half4 emissive= tex2D(_EmissiveTex,IN.uv_MainTex);
			o.Albedo = c.rgb * _Color * _ColorMultiplier;
			o.Emission = emissive*_Emissive;
		}



		ENDCG
	}

	//Fallback "Mobile/VertexLit"
}
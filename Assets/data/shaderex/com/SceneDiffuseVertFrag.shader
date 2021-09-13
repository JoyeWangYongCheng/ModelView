
Shader "LMD/Scene/DiffuseVertFrag"
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

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM

			#define FOG_LINEAR
			#define LIGHTMAP_ON 1
			#define LMD_SCENE_DIFFUSE
			#define NUMBER_HIGHT_ACCURACY

			//#pragma surface surf Battle noforwardadd vertex:vert finalcolor:FogFun
			#pragma multi_compile __ _OUTPUT_BLOOM_DATA
			#pragma multi_compile_fwdbase

			//sampler2D _MainTex;
			//half4 _Color;
			//half _ColorMultiplier;
			//half _LightIntensity;
			//uniform half st2BlackFactor;
			//half4 _Fog;
			//half _Factor;
			//half _Emissive;
			//sampler2D _EmissiveTex;
			//float _BloomIntension;

			#pragma vertex pbrVertBase
			#pragma fragment pbrFragSceneDiffuseBase

			#include "../pbr/LMDPbrInclude_ModelView.cginc"


			/*struct Input
			{
				half2 uv_MainTex;
				half fog_1;
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

			inline void FogFun(Input IN, SurfaceOutput o, inout fixed4 color)
			{
				color.rgb = lerp(_Fog, color, saturate(IN.fog_1)) * (1 - st2BlackFactor);
				half4 c = tex2D(_MainTex, IN.uv_MainTex);
				half4 emissive= tex2D(_EmissiveTex,IN.uv_MainTex);
				#ifdef _OUTPUT_BLOOM_DATA
				color = step(0.99,c.a)*emissive*emissive.a*_BloomIntension;
				#endif
			}

			void vert (inout appdata_full v, out Input o)
			{
				UNITY_INITIALIZE_OUTPUT(Input, o);
				o.fog_1 = abs(v.normal);
				half4 pos = UnityObjectToClipPos(v.vertex);
				o.fog_1 = SimulateFog(pos);
			}

			void surf(Input IN, inout SurfaceOutput o) {
				half4 c = tex2D(_MainTex, IN.uv_MainTex);
				half4 emissive= tex2D(_EmissiveTex,IN.uv_MainTex);
				o.Albedo = c.rgb * _Color * _ColorMultiplier;
				o.Emission = emissive*_Emissive;
			}*/



			ENDCG
		}

		Pass
		{
			Name "META"
			Tags { "LightMode" = "Meta" }

			Cull Off

			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta

			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature EDITOR_VISUALIZATION

			#include "UnityStandardMeta.cginc"

			float4 frag_metatemp(v2f_meta i) : SV_Target
			{

				return float4(Albedo(i.uv),1);
				// we're interested in diffuse & specular colors,
				// and surface roughness to produce final albedo.
				FragmentCommonData data = UNITY_SETUP_BRDF_INPUT(i.uv);

				UnityMetaInput o;
				UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

			#if defined(EDITOR_VISUALIZATION)
				o.Albedo = data.diffColor;
			#else
				o.Albedo = UnityLightmappingAlbedo(data.diffColor, data.specColor, data.smoothness);
			#endif
				o.SpecularColor = data.specColor;
				o.Emission = Emission(i.uv.xy);

				return UnityMetaFragment(o);
			}

			ENDCG
		}
	}

		// ------------------------------------------------------------------
		// Extracts information for lightmapping, GI (emission, albedo, ...)
		// This pass it not used during regular rendering.
	

	//Fallback "Mobile/VertexLit"
}
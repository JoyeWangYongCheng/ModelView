Shader "lmd_standard_ModelView"
{
	Properties
	{
		//_LightDir ("Light Direction", Vector) = (0.2,1,-0.4,0)
		//_LightColor("Light Main Color", Color) = (0.670588, 0.55294, 0.768627, 1.0)
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Diffuse Texture", 2D) = "white" {}

		_SurfaceColor("SurfaceColor", Color) = (1,1,1,1)

		_Occlusion("Occlusion",Range(0.0, 1)) = 0.5

		[HideInInspector]_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		_Emission("Emission Color", Color) = (1, 1, 1, 1)
		_EmissionFactor("Emission Factor", Range(0, 10)) = 1
		_BumpMap("Normal Map", 2D) = "grey" {}
		_BumpScale("Normal Map Scale",Range(0.0, 5.0)) = 1
		_MappingTex("Mapping Texture", 2D) = "grey" {}
		_AnisoTex("Aniso Texture", 2D) = "white" {}
		_EnvCubeMap("Enviroument Convolution Cubemap", Cube) = ""{}
		_EnvShadowColor("Enviroument Shadow Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_IndirectDiffuseFactor("IndirectDiffuseFactor",Range(0.0, 10.0)) = 1.0
		_IndirectSpecFactor("SpecFactor",Range(0.0, 10.0)) = 1.0
		_LightIntensity("Light Intensity",Range(0,1)) = 1
		_LightLerpFactor("LightLerpFactor",Range(0,1)) = 1
		
		_ReflectionTex("_ReflectionTex", 2D) = "black" {}
		_ReflectionFactor("ReflectionFactor",Range(0.0, 3.0)) = 1.0
		
		//_RefLerpFactor("RefLerpFactor",Range(0.0, 5.0)) = 1.0
		
		_FogFactor("FogFactor",Range(0.0, 10.0)) = 1.0
		
		_fadeUVFactor("FadeUVFactor",Range(0.0, 5.0)) = 1.0
		_fadeAddColor("FadeAddColor",Color) = (1.0, 1.0, 1.0, 1.0)
		_fadeAddTime("FadeAddTime",Range(0.0, 5.0)) = 0.1

		//_fadeBlendStart("FadeBlendStart",Range(0.0, 1.0)) = 0.1
		//_fadeBlendEnd("FadeBlendEnd",Range(0.0, 1.0)) = 0.3
		

	    _Amplitude("树干幅度",float) = 2.3
		_Frequency("树干频率",float) = 0.74
		_Amplitude01("树叶幅度",float) = 1
		_Frequency01("树叶频率",float) = 1
		_WindDir("风向",Vector) = (1,1,1)
		_Cutoff("剔除",Range(0,1)) = 1
        [Space(50)]
		[Header(Thin Film)]
		_ThinFilmMask("ThinFilmMask",2D)="white" {}
		_ThinFilmColor("ThinFilmColor", Color) = (1,1,1,1)
		_IOR("refraction index", Vector) = (0.9, 1.0, 1.1, 1.0)
		_FilmDepth("FilmDepth", Range(1, 2000)) = 755.0
		[Space(50)]

		[Toggle] USE_NRP("USE_NRP", Float) = 0
		[Toggle] USE_SELFSHADOW("USE_SELFSHADOW", Float) = 0
		[Toggle] USE_ANISOTROPY("USE_ANISOTROPY", Float) = 0
		[Toggle] USE_SSSENABLE("USE_SSSENABLE", Float) = 0
		[Toggle] USE_EMISSION("USE_EMISSION",Float)=0
		//[Toggle] USE_ALPHA_TEST("USE_ALPHA_TEST", Float) = 0
		[Toggle] _HASMETAL("HASMETAL", Float) = 0
		[Toggle] USE_GAMMA_SPACE("USE_GAMMA_SPACE", Float) = 0
		[Toggle] _FORCE_NO_USE_FORWARD_PLUS_RENDER("FORCE_NO_USE_FORWARD_PLUS_RENDER",Float) = 0
		//[Toggle] _USE_FORWARD_PLUS_RENDER("USE_FORWARD_PLUS",Float) = 0
		[Toggle] _NON_USE_PBR_GLOSSY("NON_USE_PBR_GLOSSY", Float) = 0
		[Toggle] REALTIME_REFLECTION ("REALTIME_REFLECTION", Float) = 0
		[Toggle] BLUR ("REALTIME_REFLECTION_BLUR", Float) = 0
		[Toggle] USE_AO ("USE_AO", Float) = 1
		
		[Toggle] NEED_ENV ("NEED_ENV", Float) = 1
		//[Toggle] _OCCLUSION ("OCCLUSION", Float) = 1
		[Toggle] USE_FADE_TEX ("USE_FADE_TEX", Float) = 0
		[Toggle] USE_FADE_TEX_ADD ("USE_FADE_TEX_ADD", Float) = 0
		[Toggle] USE_FADE_TO_BLEND("USE_FADE_TO_BLEND", Float) = 0
		//[Toggle] USE_NORMALMAP ("NORMALMAP", Float) = 1

		[Toggle] USE_TATTOO_TEX("USE_TATTOO_TEX", Float) = 0
		_TattooTex("Tatto Color", 2D) = "white" {}
		_TattooToggle("Tattoo Toggle", Range(0, 1)) = 0

		_IndirectLightDir("Indirect Light Direction", Vector) = (0.2,1,-0.4,0)
		[Toggle] USE_MATERIAL_DIR("USE_MATERIAL_DIR", Float) = 0

		[Toggle] USE_LERP_LIGHT("USE_LERP_LIGHT", Float) = 0

		[Toggle] NON_USE_FOG("NON_USE_FOG", Float) = 0

		[Toggle] USE_ANITREE("USE_ANITREE", Float) = 0
        [Toggle] USE_THINFILMREFLECT("USE_THINFILMREFLECT", Float) = 0

		
		
		// Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] [Toggle]_ZWrite ("__zw", Float) = 0.0

		[HideInInspector] _TypeUse("_TypeUse", Float) = 0.0
	}



	Subshader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 300
		
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			
			Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
			

			Cull Back
			//Cull Off

			CGPROGRAM
			
			#pragma target 3.0

			#define FOG_LINEAR

			#pragma shader_feature USE_COMBINE_PARAMS
			#pragma shader_feature USE_GAMMA_SPACE_ON
			
			//#pragma multi_compile_fwdbase_fullshadows
			
			//#pragma shader_feature _FORCE_NO_USE_FORWARD_PLUS_RENDER_ON
			//#pragma multi_compile _ _USE_FORWARD_PLUS_RENDER_ON
			//#pragma shader_feature _USE_COMPUTE_SHADER_ON
			
			#pragma shader_feature _ _NON_USE_PBR_GLOSSY_ON
			#pragma shader_feature _ NEED_ENV_ON
			//#pragma shader_feature REALTIME_REFLECTION_ON
			//#pragma shader_feature BLUR_ON
			#pragma shader_feature USE_AO_ON
			//#pragma shader_feature _OCCLUSION_ON
			//#pragma shader_feature USE_FADE_TEX_ON
			//#pragma shader_feature USE_FADE_TEX_ADD_ON
			//#pragma shader_feature USE_FADE_TO_BLEND_ON

			#pragma shader_feature USE_TATTOO_TEX_ON
			#pragma shader_feature _ GRAY_ON
			#pragma shader_feature USE_ALPHA_TEST_ON
			#pragma shader_feature USE_ALPHA_BLEND_ON

			#pragma shader_feature USE_MATERIAL_DIR_ON
			#pragma shader_feature USE_LERP_LIGHT_ON
			
			
			//#pragma multi_compile USE_NORMALMAP USE_NORMALMAP_ON USE_NORMALMAP_OFF
			
			#pragma shader_feature _ _NORMALMAP
			//#pragma shader_feature ___ _DETAIL_MULX2
            //#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            //#pragma shader_feature _EMISSION
            //#pragma shader_feature _METALLICGLOSSMAP
            //#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			//#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
            //#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
			
			#pragma shader_feature _HASMETAL_ON
			#pragma shader_feature USE_SSSENABLE_ON
			#pragma shader_feature USE_ANISOTROPY_ON
			#pragma shader_feature USE_EMISSION_ON
		
			#pragma shader_feature USE_NRP_ON
			#pragma shader_feature USE_SELFSHADOW_ON
			//#pragma multi_compile __ DYNAMIC_SHADOW_ENABLED

			//#pragma shader_feature _ TYPE_CHAR_HIGH TYPE_CHAR_MIDDLE TYPE_CHAR_LOW TYPE_SCENE_HIGH TYPE_SCENE_MIDDLE TYPE_SCENE_LOW
			#pragma shader_feature _ TYPE_CHAR TYPE_SCENE

			#pragma shader_feature USE_ANITREE_ON

                        #pragma	shader_feature USE_THINFILMREFLECT_ON
			#pragma shader_feature NON_USE_FOG_ON
			#pragma shader_feature USE_ROLELIGHYINTENSITY_ON
			//光面朝摄像机
			#pragma shader_feature USE_FACE_TO_CAMERA_LIGHT

			#pragma multi_compile_fwdbase
			
			//modelview
			#pragma shader_feature SHOW_NORMAL_ON
			#pragma shader_feature SHOW_DIFFUSE_ON
			#pragma shader_feature SHOW_SPECULAR_ON
			#pragma shader_feature SHOW_ENVIRONMENT_ON
			#pragma shader_feature SHOW_SPECULARANDENVIRONMENT_ON
			#pragma shader_feature SHOW_AOMASKCOLOR_ON
			#pragma shader_feature SHOW_METALLICMASKCOLOR_ON
			#pragma shader_feature SHOW_ROUGHNESSMASKCOLOR_ON
			#pragma shader_feature SHOW_SSSMASKCOLOR_ON
			#pragma shader_feature SHOW_ANISOTROPICMASKCOLOR_ON

			#pragma vertex pbrVertBase
			#pragma fragment pbrFragStandardBase
			
			//#define UNITY_STANDARD_SIMPLE 1
			//#undef UNITY_SAMPLE_FULL_SH_PER_PIXEL
			
			#include "LMDPbrInclude_ModelView.cginc"
			

			ENDCG
		}
		
		
		Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            //Blend [_SrcBlend] One
			Blend One One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

			Cull Back

			CGPROGRAM
			
			#pragma shader_feature BLUR_ON
			#pragma shader_feature USE_AO_ON
			#pragma shader_feature USE_FADE_TEX_ON
			#pragma shader_feature USE_FADE_TEX_ADD_ON
			#pragma shader_feature USE_FADE_TO_BLEND_ON
			
			#pragma shader_feature _ _NORMALMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _HASMETAL_ON
			#pragma shader_feature _SSSENABLE_ON

			#pragma shader_feature USE_TATTOO_TEX_ON
			#pragma shader_feature _ GRAY_ON
			#pragma shader_feature USE_ALPHA_TEST_ON
			#pragma shader_feature USE_MATERIAL_DIR_ON

			//光面朝摄像机
			#pragma shader_feature USE_FACE_TO_CAMERA_LIGHT
			
			#pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
			
			#pragma vertex pbrVertAdd
			#pragma fragment pbrFragStandardAdd
			
			#include "LMDPbrInclude_ModelView.cginc"

			ENDCG
        }
		
		 //  Shadow rendering pass
			Pass{
				Name "ShadowCaster"
				Tags { "LightMode" = "ShadowCaster" }

				ZWrite On ZTest LEqual

				CGPROGRAM
				#pragma target 3.0

			// -------------------------------------


			//#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _PARALLAXMAP
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			// Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
			//#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "UnityStandardShadow.cginc"

			ENDCG
		}
		
		// ------------------------------------------------------------------
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

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
            ENDCG
        }
		Pass
		{
			Name "BLOOM"
			Tags { "LightMode" = "Bloom" }

			Cull Off

			CGPROGRAM
			#pragma vertex bloomVert
			#pragma fragment bloomFrag
			#pragma shader_feature _EMISSION
			#pragma multi_compile __ _OUTPUT_BLOOM_DATA


			#include "LMDPostprocessing.cginc"
			ENDCG
		}
	}
	
	Subshader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 150
		
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			
			Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
			

			Cull Back

			CGPROGRAM
			//#pragma target 2.0

			#define FOG_LINEAR

			#pragma shader_feature USE_COMBINE_PARAMS
			#pragma shader_feature USE_GAMMA_SPACE_ON

			#pragma shader_feature _ _NON_USE_PBR_GLOSSY_ON
			#pragma shader_feature _ NEED_ENV_ON
			//#pragma shader_feature REALTIME_REFLECTION_ON
			//#pragma shader_feature BLUR_ON
			#pragma shader_feature USE_AO_ON
			//#pragma shader_feature _OCCLUSION_ON
			//#pragma shader_feature USE_FADE_TEX_ON
			//#pragma shader_feature USE_FADE_TEX_ADD_ON
			//#pragma shader_feature USE_FADE_TO_BLEND_ON

			#pragma shader_feature USE_TATTOO_TEX_ON
			#pragma shader_feature _ GRAY_ON
			#pragma shader_feature USE_ALPHA_TEST_ON
			#pragma shader_feature USE_ALPHA_BLEND_ON

			#pragma shader_feature USE_MATERIAL_DIR_ON
			#pragma shader_feature USE_LERP_LIGHT_ON


			//#pragma multi_compile USE_NORMALMAP USE_NORMALMAP_ON USE_NORMALMAP_OFF

			#pragma shader_feature _ _NORMALMAP
			//#pragma shader_feature ___ _DETAIL_MULX2
			//#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			//#pragma shader_feature _EMISSION
			//#pragma shader_feature _METALLICGLOSSMAP
			//#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			//#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			//#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF

			#pragma shader_feature _HASMETAL_ON
			#pragma shader_feature USE_SSSENABLE_ON
			#pragma shader_feature USE_ANISOTROPY_ON
			#pragma shader_feature USE_EMISSION_ON

			#pragma shader_feature USE_NRP_ON

			//#pragma shader_feature _ TYPE_CHAR_HIGH TYPE_CHAR_MIDDLE TYPE_CHAR_LOW TYPE_SCENE_HIGH TYPE_SCENE_MIDDLE TYPE_SCENE_LOW
			#pragma shader_feature _ TYPE_CHAR TYPE_SCENE
			#pragma shader_feature USE_ANITREE_ON

			#pragma shader_feature NON_USE_FOG_ON
			#pragma shader_feature USE_ROLELIGHYINTENSITY_ON
			//光面朝摄像机
			#pragma shader_feature USE_FACE_TO_CAMERA_LIGHT
			
			#pragma multi_compile_fwdbase
			//#pragma multi_compile_fog
            //#pragma multi_compile_instancing
			
			#pragma vertex pbrVertBase
			#pragma fragment pbrFragStandardBase
			
			#include "LMDPbrInclude_ModelView.cginc"

			ENDCG
		}
		
		// ------------------------------------------------------------------
        //  Shadow rendering pass
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            //#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }
		
		// ------------------------------------------------------------------
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

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
	
	FallBack "VertexLit"
	CustomEditor "Lmd_standard_GUI"
}
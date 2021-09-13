Shader "P5/st2_player_standard"
{
	Properties
	{
		//_LightDir ("Light Direction", Vector) = (0.2,1,-0.4,0)
		//_LightColor("Light Main Color", Color) = (0.670588, 0.55294, 0.768627, 1.0)
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "grey" {}
		_MappingTex("Mapping Texture", 2D) = "grey" {}
		//[Toggle] _HasMetal ("Has Metal", Float) = 1
		//[Toggle] _SSSEnable ("SSS Enable", Float) = 0 
		_EnvCubeMap("Enviroument Convolution Cubemap", Cube) = ""{}
		_EnvShadowColor("Enviroument Shadow Color", Color) = (0.670588, 0.55294, 0.768627, 1.0)
		[Toggle] _AnisoEnable ("Aniso Enable", Float) = 0
		_AnisoTex("Aniso Texture", 2D) = "white" {}
		
		
		_ReflectionTex("_ReflectionTex", 2D) = "black" {}
		_ReflectionFactor("ReflectionFactor",Range(0.0, 3.0)) = 1.0
		
		//_RefLerpFactor("RefLerpFactor",Range(0.0, 5.0)) = 1.0
		
		_FogFactor("FogFactor",Range(0.0, 10.0)) = 1.0
		
		_fadeUVFactor("FadeUVFactor",Range(0.0, 5.0)) = 1.0
		_fadeAddColor("FadeAddColor",Color) = (1.0, 1.0, 1.0, 1.0)
		_fadeAddTime("FadeAddTime",Range(0.0, 5.0)) = 0.1
			_IndirectDiffuseFactor("IndirectDiffuseFactor",Range(0.0, 10.0)) = 1.0
		_IndirectSpecFactor("IndirectSpecFactor",Range(0.0, 10.0)) = 1.0
		//_fadeBlendStart("FadeBlendStart",Range(0.0, 1.0)) = 0.1
		//_fadeBlendEnd("FadeBlendEnd",Range(0.0, 1.0)) = 0.3
		
	//	[Toggle] _FORCE_NO_USE_FORWARD_PLUS_RENDER("FORCE_NO_USE_FORWARD_PLUS_RENDER",Float) = 0
		//[Toggle] _USE_FORWARD_PLUS_RENDER("USE_FORWARD_PLUS",Float) = 0
		[Toggle] _NON_USE_PBR_GLOSSY("NON_USE_PBR_GLOSSY", Float) = 0
		[Toggle] REALTIME_REFLECTION ("REALTIME_REFLECTION", Float) = 0
		[Toggle] BLUR ("REALTIME_REFLECTION_BLUR", Float) = 0
		[Toggle] USE_AO ("USE_AO", Float) = 1
		
		[Toggle] NEED_ENV ("NEED_ENV", Float) = 1
		[Toggle] _OCCLUSION ("OCCLUSION", Float) = 1
		[Toggle] USE_FADE_TEX ("USE_FADE_TEX", Float) = 0
		[Toggle] USE_FADE_TEX_ADD ("USE_FADE_TEX_ADD", Float) = 0
		[Toggle] USE_FADE_TO_BLEND("USE_FADE_TO_BLEND", Float) = 0
		[Toggle] _NORMALMAP("NORMALMAP", Float) = 0
		
		// Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
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
			
			#pragma target 2.0
			
			//#pragma multi_compile_fwdbase_fullshadows
			
			/*#pragma multi_compile NEED_ENV NEED_ENV_ON NEED_ENV_OFF
			#pragma multi_compile REALTIME_REFLECTION REALTIME_REFLECTION_OFF REALTIME_REFLECTION_ON
			#pragma multi_compile BLUR BLUR_OFF BLUR_ON
			#pragma multi_compile USE_AO USE_AO_ON USE_AO_OFF
			#pragma multi_compile _OCCLUSION _OCCLUSION_ON _OCCLUSION_OFF*/
			
			//#pragma shader_feature _FORCE_NO_USE_FORWARD_PLUS_RENDER_ON
			//#pragma multi_compile _ _USE_FORWARD_PLUS_RENDER_ON
			//#pragma shader_feature _USE_COMPUTE_SHADER_ON
			#pragma shader_feature _NON_USE_PBR_GLOSSY_ON
			#pragma shader_feature NEED_ENV_ON
			#pragma shader_feature REALTIME_REFLECTION_ON
			#pragma shader_feature BLUR_ON
			#pragma shader_feature USE_AO_ON
			#pragma shader_feature _OCCLUSION_ON
			#pragma shader_feature USE_FADE_TEX_ON
			#pragma shader_feature USE_FADE_TEX_ADD_ON
			#pragma shader_feature USE_FADE_TO_BLEND_ON
			#pragma shader_feature  _NORMALMAP
			
			//#pragma multi_compile USE_NORMALMAP USE_NORMALMAP_ON USE_NORMALMAP_OFF
			
		//	#pragma multi_compile _ _NORMALMAP
			//#pragma shader_feature ___ _DETAIL_MULX2
            //#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            //#pragma shader_feature _EMISSION
            //#pragma shader_feature _METALLICGLOSSMAP
            //#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			//#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
            //#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
			
			//#pragma shader_feature _HASMETAL_ON
			//#pragma shader_feature _SSSENABLE_ON
			//#pragma shader_feature _ANISOENABLE_ON
			
			//#pragma multi_compile __ DYNAMIC_SHADOW_ENABLED
			
			#pragma multi_compile_fwdbase
			//#pragma multi_compile_fog
           // #pragma multi_compile_instancing
			
			#pragma vertex vert
			#pragma fragment frag
			
			//#define UNITY_STANDARD_SIMPLE 1
			//#undef UNITY_SAMPLE_FULL_SH_PER_PIXEL
			
			#include "P5PbrInclude.cginc"

			
			ColorNumber _IndirectDiffuseFactor;
			ColorNumber _IndirectSpecFactor;
			ColorNumber _FogFactor;
			
			VertexOutputForwardBaseEx vert(VertexInput v)
			{
				UNITY_SETUP_INSTANCE_ID(v);
				VertexOutputForwardBaseEx o;
				UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBaseEx, o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				
				VectorNumber4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				
				#if UNITY_REQUIRE_FRAG_WORLDPOS
					#if UNITY_PACK_WORLDPOS_WITH_TANGENT
						o.tangentToWorldAndPackedData[0].w = posWorld.x;
						o.tangentToWorldAndPackedData[1].w = posWorld.y;
						o.tangentToWorldAndPackedData[2].w = posWorld.z;
					#else
						o.posWorld = posWorld.xyz;
					#endif
				#endif
			
				o.pos = UnityObjectToClipPos(v.vertex);

				//o.tex.xy = v.uv0;
				o.tex = TexCoords(v);
				o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
				
				VectorNumber3 normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
				#ifdef _TANGENT_TO_WORLD
					/*float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

					float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
					o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
					o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
					o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];*/
					
					o.tangentToWorldAndPackedData[0].xyz  = normalize(UnityObjectToWorldDir(v.tangent.xyz));
					VectorNumber vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
					o.tangentToWorldAndPackedData[1].xyz = cross(o.tangentToWorldAndPackedData[0].xyz, normalWorld) * vv * v.tangent.w;
					o.tangentToWorldAndPackedData[2].xyz = normalWorld;
				#else
					o.tangentToWorldAndPackedData[0].xyz = 0;
					o.tangentToWorldAndPackedData[1].xyz = 0;
					o.tangentToWorldAndPackedData[2].xyz = normalWorld;
				#endif
				
				//We need this for shadow receving
				UNITY_TRANSFER_SHADOW(o, v.uv1);
				
				//#if defined(NEED_ENV_ON) && defined(REALTIME_REFLECTION_ON)
				o.screenPos = ComputeScreenPos(o.pos);
				//#endif

				o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			ColorNumber4 frag(VertexOutputForwardBaseEx i) : COLOR
			{
				UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

				FRAGMENT_SETUP(s)

				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				UnityLight mainLight = MainLight ();
				
				UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

				ColorNumber occlusion = 0.5;
				UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);
				
				VectorNumber2 uv = i.tex.xy;
			
				VectorNumber3 normalWorld = s.normalWorld;
				
				VectorNumber3 lightDir;
				//平行光
				//if(mainLight.dir.x == 0.0 && mainLight.dir.y == 0.0 && mainLight.dir.z == 0.0)
				//	lightDir = normalWorld;
				//else
					lightDir = gi.light.dir;
				
				ColorNumber3 finalColor = 0;
				
				VectorNumber3 viewDir = normalize(UnityWorldSpaceViewDir(s.posWorld));
				VectorNumber nDotV = saturate(dot(normalWorld, viewDir));
				ColorNumber4 albedo = tex2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw);
			#ifdef USE_FADE_TEX_ON
				albedo.rgb = CalFadedAlbedoColor(albedo.rgb,uv);
			#endif
				albedo = albedo * albedo;
				ColorNumber3 mappingInfo = tex2D(_MappingTex, uv * _MappingTex_ST.xy + _MappingTex_ST.zw);
				ColorNumber roughness = lerp(0.04, 1, saturate(mappingInfo.z));
				ColorNumber metallic = mappingInfo.x;
				
			#ifdef _NON_USE_PBR_GLOSSY_ON
				finalColor += DiffuseShading(albedo, metallic, gi.light.color.rgb,normalWorld, lightDir,1);
			#else
				finalColor += PbrShading(albedo,metallic,roughness,gi.light.color.rgb,normalWorld,viewDir,nDotV,lightDir,1).rgb;
			#endif
				
				//sh and lightmaps
				//ambient += max(half3(0,0,0), ShadeSH9 (half4(normal, 1.0)));
				//finalColor += albedo * (1 - metallic) * max(half3(0,0,0), ShadeSH9 (half4(normalWorld, 1.0))) * _IndirectDiffuseFactor;
				finalColor += albedo * (1 - metallic) * gi.indirect.diffuse * _IndirectDiffuseFactor;
				
				VectorNumber nDotL = saturate(dot(normalWorld, lightDir));
				ColorNumber3 envShadow = lerp(_EnvShadowColor, 1, nDotL);
				
	#ifdef NEED_ENV_ON			
		#ifdef REALTIME_REFLECTION_ON
				VectorNumber2 uvxy =(i.screenPos.xy / i.screenPos.w);
			#ifdef BLUR_ON
				ColorNumber4 envir = GetBlurColor( uvxy,int(roughness * 8)) * _ReflectionFactor;
			#else
				ColorNumber4 envir = tex2Dlod(_ReflectionTex, VectorNumber4(uvxy,int(roughness * 8),int(roughness * 8))) * _ReflectionFactor;
			#endif

		#else
				VectorNumber3 refDir = normalize(reflect(-viewDir, normalWorld));
				ColorNumber4 envir = texCUBElod(_EnvCubeMap, VectorNumber4(refDir, int(roughness * 8)));
				envir.rgb *= envir.a;
		#endif
			
			#if _HASMETAL_ON
				ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
				finalColor += lerp(0.6, 1, nDotL) * envir * envir_brdf(base, roughness, nDotV) * envShadow;
			#else
				finalColor += lerp(0.6, 1, nDotL) * envir * envir_brdf_nonmetal(roughness, nDotV) * envShadow;
			#endif
	#endif
	
	//#ifndef _FORCE_NO_USE_FORWARD_PLUS_RENDER_ON
	//		#ifdef _USE_FORWARD_PLUS_RENDER_ON
	//			finalColor += AllDirectLightsShading(albedo.xyz, metallic, roughness, s.posWorld.xyz, normalWorld, viewDir, nDotV,1);
	//		
	//			//test
	//			//finalColor = 0;
	//			//all other point lights
	//			finalColor += AllPointLightsShading(i.screenPos.xy / i.screenPos.w, albedo.xyz, metallic, roughness, s.posWorld.xyz, normalWorld, viewDir, nDotV,1);
	//			
	//			//test
	//			//return fixed4(finalColor,1);
	//		#endif
	//#endif

			#if defined(USE_AO_ON) && defined(_NORMALMAP)
				ColorNumber aoValue = s.ao;//normalColor.z;
				aoValue = lerp(lerp(1, aoValue, nDotV), aoValue, 2 * saturate(0.5 - aoValue));
				finalColor *= aoValue;
			#endif
			
				finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
			
				UNITY_APPLY_FOG_COLOR(i.fogCoord, finalColor.rgb,unity_FogColor * _FogFactor);
				return ColorNumber4(finalColor, 1);
			}

			ENDCG
		}
		
		
		//Pass
  //      {
  //          Tags { "LightMode" = "ForwardAdd" }
  //          //Blend [_SrcBlend] One
		//	Blend One One
  //          Fog { Color (0,0,0,0) } // in additive pass fog should be black
  //          ZWrite Off
  //          ZTest LEqual

		//	Cull Back

		//	CGPROGRAM
		//	
		//	#pragma shader_feature BLUR_ON
		//	#pragma shader_feature USE_AO_ON
		//	#pragma shader_feature USE_FADE_TEX_ON
		//	#pragma shader_feature USE_FADE_TEX_ADD_ON
		//	#pragma shader_feature USE_FADE_TO_BLEND_ON
		//	
		//	#pragma multi_compile _ _NORMALMAP
		//	#pragma shader_feature ___ _DETAIL_MULX2
		//	#pragma shader_feature _HASMETAL_ON
		//	#pragma shader_feature _SSSENABLE_ON
		//	#pragma shader_feature _ANISOENABLE_ON
		//	
		//	#pragma multi_compile_fwdadd_fullshadows
  //          #pragma multi_compile_fog
		//	
		//	#pragma vertex vert
		//	#pragma fragment frag
		//	
		//	#include "P5PbrInclude.cginc"
		//	
		//	VertexOutputForwardBaseAdd vert(VertexInput v)
		//	{
		//		UNITY_SETUP_INSTANCE_ID(v);
		//		VertexOutputForwardBaseAdd o;
		//		UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBaseAdd, o);
		//		UNITY_TRANSFER_INSTANCE_ID(v, o);
		//		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		//		
		//		VectorNumber4 posWorld = mul(unity_ObjectToWorld, v.vertex);
		//		
		//		#if UNITY_REQUIRE_FRAG_WORLDPOS
		//			#if UNITY_PACK_WORLDPOS_WITH_TANGENT
		//				o.tangentToWorldAndPackedData[0].w = posWorld.x;
		//				o.tangentToWorldAndPackedData[1].w = posWorld.y;
		//				o.tangentToWorldAndPackedData[2].w = posWorld.z;
		//			#else
		//				o.posWorld = posWorld.xyz;
		//			#endif
		//		#endif
		//	
		//		o.pos = UnityObjectToClipPos(v.vertex);

		//		//o.tex.xy = v.uv0;
		//		o.tex = TexCoords(v);
		//		o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
		//		
		//		VectorNumber3 normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
		//		#ifdef _TANGENT_TO_WORLD
		//			
		//			o.tangentToWorldAndPackedData[0].xyz  = normalize(UnityObjectToWorldDir(v.tangent.xyz));
		//			VectorNumber vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
		//			o.tangentToWorldAndPackedData[1].xyz = cross(o.tangentToWorldAndPackedData[0].xyz, normalWorld) * vv * v.tangent.w;
		//			o.tangentToWorldAndPackedData[2].xyz = normalWorld;
		//			
		//		#else
		//			o.tangentToWorldAndPackedData[0].xyz = 0;
		//			o.tangentToWorldAndPackedData[1].xyz = 0;
		//			o.tangentToWorldAndPackedData[2].xyz = normalWorld;
		//		#endif
		//		
		//		//We need this for shadow receving
		//		UNITY_TRANSFER_SHADOW(o, v.uv1);
		//		
		//		return o;
		//	}

		//	//add
		//	ColorNumber4 frag(VertexOutputForwardBaseAdd i) : COLOR
		//	{
		//		UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

		//		VectorNumber3 posWorld = IN_WORLDPOS(i)

		//		UNITY_SETUP_INSTANCE_ID(i);
		//		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

		//		UnityLight mainLight;
		//		
		//		//平行光
		//		if(0.0 == _WorldSpaceLightPos0.w)
		//			mainLight.dir = _WorldSpaceLightPos0.xyz;
		//		else
		//			mainLight.dir = normalize(_WorldSpaceLightPos0.xyz - posWorld.xyz);
		//		
		//		UNITY_LIGHT_ATTENUATION(atten, i, posWorld);
		//		
		//		mainLight.color = _LightColor0.rgb * atten;
		//		
		//		VectorNumber3 lightDir = mainLight.dir;
		//		
		//		VectorNumber3 viewDir = normalize(UnityWorldSpaceViewDir(posWorld));
		//		//VectorNumber3 halfDir = normalize(lightDir + viewDir);
		//		VectorNumber2 uv = i.tex.xy;
		//		
		//		VectorNumber3 binormal = normalize(i.tangentToWorldAndPackedData[1].xyz);
		//	#ifdef _NORMALMAP
		//		VectorNumber3 tangent = normalize(i.tangentToWorldAndPackedData[0].xyz);
		//		ColorNumber4 normalColor = tex2D(_BumpMap, uv * _BumpMap_ST.xy + _BumpMap_ST.zw);
		//		
		//	#ifdef USE_FADE_TEX_ON
		//		normalColor = CalFadedNormal(normalColor,uv);
		//	#endif
		//		
		//		normalColor.xy = normalColor.xy * 2 - 1;
		//		VectorNumber3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
		//		VectorNumber3 normal = normalize(normalize(i.tangentToWorldAndPackedData[2].xyz) + normalOffset);
		//	#else
		//		VectorNumber3 normal = normalize(i.tangentToWorldAndPackedData[2].xyz);
		//	#endif
		//		
		//		ColorNumber3 diffuse = 0;
		//		ColorNumber3 specular = 0;
		//		
		//		//VectorNumber nDotH = saturate(dot(normal, halfDir));
		//		VectorNumber nDotV = saturate(dot(normal, viewDir));
		//		//VectorNumber vDotH = saturate(dot(viewDir, halfDir));
		//		ColorNumber4 albedo = tex2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw);
		//		
		//	#ifdef USE_FADE_TEX_ON
		//		
		//		albedo.rgb = CalFadedAlbedoColor(albedo.rgb,uv);
		//		
		//	#endif
		//		
		//		ColorNumber3 m = tex2D(_MappingTex, uv * _MappingTex_ST.xy + _MappingTex_ST.zw);
		//		VectorNumber nDotL = dot(normal, lightDir);
		//	
		//		nDotL = saturate(nDotL);
		//		ColorNumber s1 = 0;
		//	
		//		ColorNumber metallic = m.x;
		//		//ColorNumber roughness = lerp(0.04, 1, saturate(m.z));
		//		albedo = albedo * albedo;
		//		//ColorNumber3 envShadow = lerp(_EnvShadowColor, 1, nDotL);
		//		diffuse += albedo * (1 - metallic) * ((nDotL + s1) * mainLight.color.rgb );
		//		//ColorNumber3 base = lerp(albedo, 0.04, 1 - metallic);
		//		//ColorNumber3 F = f_schlick(base, vDotH);
		//		//ColorNumber D = d_ggx(roughness, nDotH);
		//		//ColorNumber G = geometric(nDotV, nDotL, roughness);
		//		//specular += D * F * G * (nDotL * mainLight.color.rgb );

		//		ColorNumber3 finalColor = (diffuse + specular);
		//	#if defined(USE_AO_ON) && defined(_NORMALMAP)
		//		ColorNumber aoValue = normalColor.z;
		//		ColorNumber ao = lerp(lerp(1, aoValue, nDotV), aoValue, 2 * saturate(0.5 - aoValue));
		//		finalColor *= ao;
		//	#endif
		//		
		//		finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
		//		
		//		return ColorNumber4(finalColor, 1);
		//	}

		//	ENDCG
  //      }
		//
		 //  Shadow rendering pass
        Pass 
		{
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
			//#pragma target 3.0

            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _PARALLAXMAP
            #pragma multi_compile_shadowcaster
           // #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }
		//
		// ------------------------------------------------------------------
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        pass
        {
            name "meta"
            tags { "lightmode"="meta" }

				CGPROGRAM

         
            #pragma vertex vert_meta
            #pragma fragment frag_meta

            #pragma shader_feature _emission
            #pragma shader_feature _metallicglossmap
            #pragma shader_feature _ _smoothness_texture_albedo_channel_a
            #pragma shader_feature ___ _detail_mulx2
            #pragma shader_feature editor_visualization

            #include "unitystandardmeta.cginc"
				ENDCG
        }
//	}
	
	
	}
	//
	FallBack "Unity/VertexLit"
	CustomEditor "St2_player_standard_GUI"
}
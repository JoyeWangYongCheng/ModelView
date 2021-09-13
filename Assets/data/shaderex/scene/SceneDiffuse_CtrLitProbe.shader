
Shader  "LMD/Scene/Diffuse_CtrLitProbe"
{
	Properties
	{
		_Color("Main Color", Color) = (1, 1, 1, 1)
		//_LightDir("Light Direction", Vector) = (0.2,1,-0.4,0)
	//	_LightColor("Light Main Color", Color) = (0.670588, 0.55294, 0.768627, 1.0)
		_MainTex("Diffuse Texture", 2D) = "white" {}
		//_NormalMap("Normal Map", 2D) = "grey" {}
        _LightProVal("LightProVal",Range(0,5)) =0.2
        _lumance("_lumance",float)=1.0
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 150

		CGPROGRAM
		#pragma surface surf Battle noforwardadd
		
    #include "UnityImageBasedLighting.cginc"
    #include "UnityStandardUtils.cginc"
     #include "UnityShadowLibrary.cginc"
    float _LightProVal;
     float _lumance;


		inline fixed4 LightingBattle(SurfaceOutput s, UnityGI gi)
		{
			fixed4 c = 0;

			#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
				c.rgb += s.Albedo * gi.indirect.diffuse*_lumance;
			#endif
               
               
             //  s.Albedo= s.Albedo+s.Albedo* gi.indirect.diffuse*_LightProVal;
			return fixed4(lerp(s.Albedo,s.Albedo* gi.indirect.diffuse,_LightProVal),1);
		}
       half3 ShadeSHPerVertexbattel (half3 normal, half3 ambient)


    {
    #if UNITY_SAMPLE_FULL_SH_PER_PIXEL
        // Completely per-pixel
        // nothing to do here
    #elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        // Completely per-vertex
       ambient += max(half3(0,0,0), ShadeSH9 (half4(normal, 1.0)));
    #else
        // L2 per-vertex, L0..L1 & gamma-correction per-pixel

        // NOTE: SH data is always in Linear AND calculation is split between vertex & pixel
        // Convert ambient to Linear and do final gamma-correction at the end (per-pixel)
        #ifdef UNITY_COLORSPACE_GAMMA
            ambient = GammaToLinearSpace (ambient);
        #endif
        ambient += SHEvalLinearL2 (half4(normal, 1.0));     // no max since this is only L2 contribution
    #endif

    return ambient;
}


inline UnityGI UnityGI_BattelBase(UnityGIInput data, half occlusion, half3 normalWorld)
{
    UnityGI o_gi;
    ResetUnityGI(o_gi);

    // Base pass with Lightmap support is responsible for handling ShadowMask / blending here for performance reason
    #if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
        half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
        float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
        float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
        data.atten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
    #endif

    o_gi.light = data.light;
    o_gi.light.color *= data.atten;

    #if UNITY_SHOULD_SAMPLE_SH
        o_gi.indirect.diffuse =   ShadeSHPerVertexbattel(normalWorld, data.ambient);
    #endif

    #if defined(LIGHTMAP_ON)
        // Baked lightmaps
        half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
        half3 bakedColor = DecodeLightmap(bakedColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
            o_gi.indirect.diffuse += DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap (o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
            #endif

        #else // not directional lightmap
            o_gi.indirect.diffuse += bakedColor;

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
            #endif

        #endif
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        // Dynamic lightmaps
        fixed4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, data.lightmapUV.zw);
        half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw);
            o_gi.indirect.diffuse += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, normalWorld);
        #else
            o_gi.indirect.diffuse += realtimeColor;
        #endif
    #endif

    o_gi.indirect.diffuse *= occlusion;
    return o_gi;
}
inline UnityGI GlobalIlluminationBattel(UnityGIInput data, half occlusion, half3 normalWorld)
{
    return UnityGI_BattelBase(data, occlusion, normalWorld);
}

     inline void LightingBattle_GI(SurfaceOutput s,UnityGIInput data,inout UnityGI gi)
		{
			gi =  GlobalIlluminationBattel(data, 1.0, s.Normal);
			
		}
    











		sampler2D _MainTex;
		float4 _Color;
       

		struct Input {
			float2 uv_MainTex;
		};

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color*_lumance;
			o.Alpha = c.a;
		
		}
		ENDCG
	}

		//Fallback "Mobile/VertexLit"
}
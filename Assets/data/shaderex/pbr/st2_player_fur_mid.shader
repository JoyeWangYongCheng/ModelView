Shader "streetball2/model_fur_mid_runtime"
{
	Properties
	{
		_Color("Main Color", Color) = (1, 1, 1, 1)
		_Emission("Emission Color", Color) = (1, 1, 1, 1)
		_EmissionFactor("Emission Factor", Range(0, 10)) = 1
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "grey" {}
		_MappingTex("Mapping Texture", 2D) = "grey" {}
		_EnvCubeMap("Enviroument Convolution Cubemap", Cube) = ""{}
		_EnvShadowColor("Enviroument Shadow Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_AnisoTex("Aniso Texture", 2D) = "white" {}
		_SSSEnable("_SSSEnable",float) = 1
		_AnisoEnable("_AnisoEnable",float) = 0
		_HasMetal("_HasMetal",float) = 1


		_FurLightIntensity("Fur Light Intensiy",Range(0,1)) = 0.15
		_MaskTex("Mask",2D) = "black" {}
		_FlowMap("Flow map",2D) = "black"{}
		_FurColor("Fur Color",Color) = (0.5,0.5,0.5,1)
		_FurLength("Fur Lenght",float) = 0.025
		_Offset("",Range(0,5)) = 0
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0 // how "thick"
		_CutoffEnd("Alpha Cutoff end", Range(0,1)) = 0.6 // how thick they are at the end
		_FurMoveStrength("FurMoveStrength",float) = 0
		_Roughness("Roughness",Range(0,1)) = 0
		_SpecularOffset("Specular Offet",float) = 0
			// _Color("_Color",Color) = (1,1,1,1)


		_MinOcclusion("Min Occlusion",Range(0,1)) = .7
		_MaxOcclusion("Max Occlusion",Range(0,1)) = .85

			//_MinHeightAtten("Min Height Attenuation",Range(0,1)) = 0.1
	}

		Subshader
		{
			// ZWrite Off
			Tags { "LightMode" = "ForwardBase"  "Queue" = "Transparent" "RenderType" = "Opaque" }
			Blend SrcAlpha OneMinusSrcAlpha, One One
			// Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue"="Transparent"}
			LOD 100

			Pass
			{

				ZWrite On
				Blend Off
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "com.cginc"

				half4 frag(V2f i) : COLOR
				{

					half3 tangent = normalize(i.tangent);
					half3 binormal = normalize(i.binormal);
					half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					half3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
					half3 halfDir = normalize(lightDir + viewDir);
					half2 uv = i.tex.xy;
					half4 normalColor = tex2D(_NormalMap, uv);
					normalColor.xy = normalColor.xy * 2 - 1;
					half3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
					half3 normal = normalize(normalize(i.normalWorld) + normalOffset);
					half3 diffuse = 0;
					half3 specular = 0;
					half3 refDir = normalize(reflect(-viewDir, normal));
					half nDotH = saturate(dot(normal, halfDir));
					half nDotV = saturate(dot(normal, viewDir));
					half vDotH = saturate(dot(viewDir, halfDir));
					half4 albedo = tex2D(_MainTex, uv);
					// return albedo;
					half4 m = tex2D(_MappingTex, uv);
					half nDotL = dot(normal, lightDir);

					//float d = _D;
					float u = abs(nDotL - nDotV);

					float4 shadowPos = float4(i.posWorld.xyz,1);
					float4 ndcpos = mul(_HQCharCameraVP,shadowPos);
					ndcpos.xyz /= ndcpos.w;
					float3 uvpos = ndcpos * 0.5 + 0.5;

					half atten = 1;            

				half3 sssAlbedo = saturate(albedo - max(max(max(albedo.x, albedo.y), albedo.z) - 0.39, 0.1));

				half sss = clamp(m.y * 2 - 1, 0, 1);
				nDotL = lerp(min(saturate(nDotL), atten), pow(min(max(0, nDotL + 0.45) / 1.45, atten), 2), sss);
				half sssa = smoothstep(0.51f, 0, (clamp(nDotL, -1, 0) + nDotL) / 2);
				half sssb = saturate((0.53f - lerp(saturate(nDotL), saturate(-nDotL), 0.61f)) / 0.53f);
				half3 s1 = sssb * sssa * sss * sssAlbedo * 2.35f * 0.3f;
				half3 s2 = (2 - nDotV) * sssAlbedo * sss;

				half metallic = m.x;
				half roughness = lerp(0.04, 1, saturate(m.z));
				albedo = albedo * albedo;
				half3 envShadow = lerp(_EnvShadowColor, 1, nDotL);
				half4 n = half4(normal, 1);
				half3 sh = _ShadeSH9(n);
				diffuse += albedo * (1 - metallic) * ((nDotL + s1)  + (envShadow * sh + s2 * sh));
				half3 base = lerp(albedo, 0.04, 1 - metallic);
				half3 F = f_schlick(base, vDotH);
				float D = d_ggx(roughness, nDotH);
				half G = geometric(nDotV, nDotL, roughness);
				specular += D * F * G * nDotL ;

										half4 envir = TEX_CUBE_LOD(_EnvCubeMap, half4(refDir, int(roughness * 8)));
										envir.rgb *= envir.a;

										specular += lerp(0.6, 1, nDotL) * envir * envir_brdf(base, roughness, nDotV) * envShadow;


										half aoValue = normalColor.z;
										half ao = lerp(lerp(1, aoValue, nDotV), aoValue, 2 * saturate(0.5 - aoValue));
										half3 finalColor = (diffuse + specular) * ao;
										finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
										finalColor += _Emission * _EmissionFactor * (1 - normalColor.w)*albedo;

										//    float y = mul(unity_ObjectToWorld,float4(0,0,0,1));
										//    float dy = i.posWorld.y - y;
										//    float heightAtten =  smoothstep(0,1,dy/.9);
										//    heightAtten = max(_MinHeightAtten,heightAtten);
										//    heightAtten = 1;

											return half4((finalColor * _Color.rgb), m.w);
										}

										ENDCG
									}



			Pass
			{
				ZWrite Off
				Tags{ "LightMode" = "ForwardBase"}

				CGPROGRAM
				#define LAYER 2 
				#define UVOFFSET half2(-1,-1)       
				#include "com_fur.cginc"
				#pragma vertex furVertex
				#pragma fragment furFrag
				ENDCG
			}
			//Pass
			//{
			//	Tags{ "LightMode" = "ForwardBase"}
			//	CGPROGRAM
			//	#define LAYER 3
			//	#define UVOFFSET half2(1,-1)        
			//	#include "com_fur.cginc"
			//	#pragma vertex furVertex
			//	#pragma fragment furFrag
			//	ENDCG
			//}

			//Pass
			//{
			//	ZWrite On
			//	Tags{ "LightMode" = "ForwardBase"}
			//	CGPROGRAM
			//	#define LAYER 4  
			//	#define UVOFFSET half2(-1,1)      
			//	#include "com_fur.cginc"
			//	#pragma vertex furVertex
			//	#pragma fragment furFrag
			//	ENDCG
			//}

			//	Pass
			//{
			//	ZWrite On
			//	Tags{ "LightMode" = "ForwardBase"}
			//	CGPROGRAM
			//	#define LAYER 5  
			//	#define UVOFFSET half2(1,1)      
			//	#include "com_fur.cginc"
			//	#pragma vertex furVertex
			//	#pragma fragment furFrag
			//	ENDCG
			//}
			//Pass
			//{
			//	ZWrite Off
			//	CGPROGRAM
			//	#define LAYER 6 
			//	#define UVOFFSET half2(-1,-1)       
			//	#include "com_fur.cginc"
			//	#pragma vertex furVertex
			//	#pragma fragment furFrag
			//	ENDCG
			//}

			//Pass
			//{
			//	ZWrite Off
			//	CGPROGRAM
			//	#define LAYER 7  
			//	#define UVOFFSET half2(-1,1)      
			//	#include "com_fur.cginc"
			//	#pragma vertex furVertex
			//	#pragma fragment furFrag
			//	ENDCG
			//}


			//Pass
			//{
			//			ZWrite Off
			//		// Cull back
			//		// Blend SrcAlpha OneMinusSrcAlpha, One One
			//		CGPROGRAM
			//		#define LAYER 8 
			//		#define UVOFFSET half2(1,-1)      
			//		#include "com_fur.cginc"
			//		#pragma multi_compile_fwdbase

			//		#pragma vertex furVertex
			//		#pragma fragment furFragShadow
			//		ENDCG
			//}

		}

			//FallBack "VertexLit"
}
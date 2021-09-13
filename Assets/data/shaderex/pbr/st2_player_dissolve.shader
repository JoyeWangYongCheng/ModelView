Shader "streetball2/model_dissolve_runtime"
{
	Properties
	{
		_Color("Main Color", Color) = (1, 1, 1, 1)
		_Emission("Emission Color", Color) = (1, 1, 1, 1)
		_EmissionFactor("Emission Factor", Range(0, 10)) = 1
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "grey" {}
		_MappingTex("Mapping Texture", 2D) = "grey" {}
		_MainTex02("Diffuse Texture 02", 2D) = "white" {}
		_NormalMap02("Normal Map 02", 2D) = "grey" {}
		_MappingTex02("Mapping Texture 02", 2D) = "grey" {}
		_EnvCubeMap("Enviroument Convolution Cubemap", Cube) = ""{}
		_EnvShadowColor("Enviroument Shadow Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_AnisoTex("Aniso Texture", 2D) = "white" {}
		_SSSEnable("_SSSEnable",float) = 1
		_AnisoEnable("_AnisoEnable",float) = 0
		_HasMetal("_HasMetal",float) = 1

		_DissolveTex("_DissolveTex", 2D) = "white" {}
		_Dissolve("Dissolve",Range(0,1)) = 0
		_Hardness("Hardness",Range(0,1)) = 1
		_WidthColor("Width Color", Color) = (1, 1, 1, 1)
		_Width("Width",Range(0,1)) = 0.04
		_Start("Start",float)=-1.4
		_End("End",float)=2.2
		[MaterialToggle]_Inversion("Inversion",Int) =0
		_HasMetal("_HasMetal",float) = 1

		_SelfShadowIntensity("Shadow Intensity",Float)=1.0
	}

		Subshader
		{
			// ZWrite Off
			Tags {"RenderType" = "Opaque" }
			Cull Back
			LOD 100

			Pass
			{
				Tags { "LightMode" = "ForwardBase" }
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "com.cginc"

//计算光照的方法
				inline float4 CalculateLight(V2f i,float4 albedo,float4 normalColor, float4 m)
				{
					half3 tangent = normalize(i.tangent);
					half3 binormal = normalize(i.binormal);
					half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					half3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
					half3 halfDir = normalize(lightDir + viewDir);
					
					
					normalColor.xy = normalColor.xy * 2 - 1;
					half3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
					half3 normal = normalize(normalize(i.normalWorld) + normalOffset);
					half3 diffuse = 0;
					half3 specular = 0;
					half3 refDir = normalize(reflect(-viewDir, normal));
					half nDotH = saturate(dot(normal, halfDir));
					half nDotV = saturate(dot(normal, viewDir));
					half vDotH = saturate(dot(viewDir, halfDir));
					
					// return albedo;

					half nDotL = dot(normal, lightDir);

					float4 shadowPos = float4(i.posWorld.xyz,1);
					float4 ndcpos = mul(_HQCharCameraVP,shadowPos);
					ndcpos.xyz /= ndcpos.w;
					float3 uvpos = ndcpos * 0.5 + 0.5;
					half atten = PCFForNoTrans(uvpos.xy, ndcpos.z, _Bias);
					//half atten = 1;            

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

					return half4((finalColor * _Color.rgb), m.w);
					
				}

				half4 frag(V2f i) : COLOR
				{

//溶解			
				half2 uv = i.tex.xy;

				half4 albedo = tex2D(_MainTex, uv);
				half4 m = tex2D(_MappingTex, uv);
				half4 normalColor = tex2D(_NormalMap, uv);

				half4 albedo02 = tex2D(_MainTex02, uv);
				half4 m02 = tex2D(_MappingTex02, uv);
				half4 normalColor02 = tex2D(_NormalMap02, uv);

				float4 color01 = CalculateLight(i,albedo,normalColor,m);
				float4 color02 = CalculateLight(i,albedo02,normalColor02,m02);




				float4 c = DoubleDissolveFunction(uv,i.objPos.y,color01,color02);

				return c;
				}

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
				#include "com.cginc"
				#pragma shader_feature _EMISSION
				#pragma multi_compile __ _OUTPUT_BLOOM_DATA


				V2f bloomVert(A2v v)
				{
					V2f o;
					o.objPos = v.vertex;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.tex = v.texcoord;
					o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.normalWorld  = normalize(UnityObjectToWorldNormal(v.normal));
					o.tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
					float vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
					o.binormal = cross(o.tangent, o.normalWorld) * vv * v.tangent.w;
					return o;
				}

//计算光照的方法
				inline float4 CalculateLight(V2f i,float4 albedo,float4 normalColor, float4 m)
				{
					half3 tangent = normalize(i.tangent);
					half3 binormal = normalize(i.binormal);
					half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					half3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
					half3 halfDir = normalize(lightDir + viewDir);
					
					
					normalColor.xy = normalColor.xy * 2 - 1;
					half3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
					half3 normal = normalize(normalize(i.normalWorld) + normalOffset);

					

					half3 specular = 0;
					half3 refDir = normalize(reflect(-viewDir, normal));
					half nDotH = saturate(dot(normal, halfDir));
					half nDotV = saturate(dot(normal, viewDir));
					half vDotH = saturate(dot(viewDir, halfDir));
					

					half nDotL = dot(normal, lightDir);

					half sss = clamp(m.y * 2 - 1, 0, 1);
					nDotL = lerp(min(saturate(nDotL), 1), pow(min(max(0, nDotL + 0.45) / 1.45, 1), 2), sss);


					half metallic = m.x;
					half roughness = lerp(0.04, 1, saturate(m.z));
					albedo = albedo * albedo;

					half4 n = half4(normal, 1);

					half3 base = lerp(albedo, 0.04, 1 - metallic);
					half3 F = f_schlick(base, vDotH);
					float D = d_ggx(roughness, nDotH);
					half G = geometric(nDotV, nDotL, roughness);
					specular += D * F * G * nDotL ;

					float3 bloomColor = (1 - m.w)*specular*0.1 + albedo * _Emission * _EmissionFactor * (1 - normalColor.w)*2.5;
					return float4(bloomColor, 1);
				}


				half4 bloomFrag(V2f i) : COLOR
				{
					half2 uv = i.tex.xy;
					half4 albedo = tex2D(_MainTex, uv);
					half4 normalColor = tex2D(_NormalMap, uv);
					half4 m = tex2D(_MappingTex, uv);

					half4 albedo02 = tex2D(_MainTex02, uv);
					half4 m02 = tex2D(_MappingTex02, uv);
					half4 normalColor02 = tex2D(_NormalMap02, uv);

					float4 color01 = CalculateLight(i,albedo,normalColor,m);
					float4 color02 = CalculateLight(i,albedo02,normalColor02,m02);
					
					float4 c = DoubleDissolveFunction(uv,i.objPos.y,color01,color02);
					return c;
				}

				ENDCG
			}

		}	
}
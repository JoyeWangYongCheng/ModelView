Shader "TA_Test/pbr"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_FresnelValue ("Fresnel Value",float) = 1
		_Value01 ("Value01",float) = 1
		_Value02 ("Value02",float) = 1
		_Emission("Emission Color", Color) = (1, 1, 1, 1)
		_EmissionFactor("Emission Factor", Range(0, 10)) = 1
		_LightDir ("Light Direction", Vector) = (0.2,1,-0.4,0)
		_LightColor("Light Main Color", Color) = (0.670588, 0.55294, 0.768627, 1.0)
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "grey" {}
		_MappingTex("Mapping Texture", 2D) = "grey" {}
		_EnvCubeMap("Enviroument Convolution Cubemap", Cube) = ""{}
		_EnvShadowColor("Enviroument Shadow Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_AnisoTex("Aniso Texture", 2D) = "white" {}
	}
	SubShader
	{
		
		Tags { "LightMode" = "ForwardBase"  "RenderType" = "Opaque" }

		Pass
		{
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
				float3 posWorld : TEXCOORD1;
				float3 normalWorld : TEXCOORD2;
				float3 tangent : TEXCOORD3;
				float3 binormal : TEXCOORD4;
				float3 lightDir : TEXCOORD5;
			};

			uniform float4 _Color;
			uniform sampler2D _MainTex;
			uniform sampler2D _NormalMap;
			uniform sampler2D _MappingTex;
			uniform samplerCUBE _EnvCubeMap;
			uniform half3 _EnvShadowColor;
			uniform sampler2D _AnisoTex;
			uniform half4 _LightDir;
			uniform half4 _Emission;
			uniform half _EmissionFactor;

			float _DynamicShadowSize;
			float4x4 _DynamicShadowMatrix;
			float4 _DynamicShadowParam;
			sampler2D _DynamicShadowTexture;
			float3 _LightColor;
			float _FresnelValue;
			float _Value01;
			float _Value02;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
                o.tex = half4(v.texcoord.xy, v.texcoord.xy);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
				o.tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
				//切线长度跟1.5比较，确定副法线方向 求出来的值 要么是1  要么是-1
				float vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
				o.binormal = cross(o.tangent, o.normalWorld) *vv * v.tangent.w;
				o.lightDir = normalize(_LightDir);
				return o;
			}

			// fixed3 fresnelSchlick(float cosTheta, fixed3 F0)
			// {
			// 	return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
			// }

			// fixed DistributionGGX(fixed3 N, fixed3 H, fixed roughness)
			// {
			//     fixed a      = roughness*roughness;
			//     fixed a2     = a*a;
			//     fixed NdotH  = max(dot(N, H), 0.0);
			//     fixed NdotH2 = NdotH*NdotH;

			//     fixed nom   = a2;
			//     fixed denom = (NdotH2 * (a2 - 1.0) + 1.0);
			//     denom = UNITY_PI * denom * denom;

			//     return nom / denom;
			// }

			// fixed GeometrySchlickGGX(fixed NdotV, fixed roughness)
			// {
			//     fixed r = (roughness + 1.0);
			//     fixed k = (r*r) / 8.0;

			//     fixed nom   = NdotV;
			//     fixed denom = NdotV * (1.0 - k) + k;

			//     return nom / denom;
			// }

			// fixed GeometrySmith(fixed3 N, fixed3 V, fixed3 L, fixed roughness)
			// {
			//     fixed NdotV = max(dot(N, V), 0.0);
			//     fixed NdotL = max(dot(N, L), 0.0);
			//     fixed ggx2  = GeometrySchlickGGX(NdotV, roughness);
			//     fixed ggx1  = GeometrySchlickGGX(NdotL, roughness);

			//     return ggx1 * ggx2;
			// }
			half sg(half t, half a)
			{
				half aa = a * a;
				return aa * aa * a;
				// return pow(a, t);
				//half k = t * 1.442695f + 1.089235f;
				//return exp2(k * a - k);
			}

			half3 f_schlick(half3 f0, half vDotH)
			{
				return f0 + (1 - f0) * pow(1.0 - vDotH, 5.0);
			}

			float d_ggx(half roughness, half nDotH)
			{
				half a = roughness * roughness;
				half a2 = a * a;
				half d = (nDotH * a2 - nDotH) * nDotH + 1;
				//return min(10000, a2 / (d * d + 0.00001) * INV_PI); 
				return min(10000, a2 / (d * d + 0.00001));
			}

			fixed d_ggx(fixed3 N, fixed3 H, fixed roughness)
			{
			    fixed a      = roughness*roughness;
			    fixed a2     = a*a;
			    fixed NdotH  = max(dot(N, H), 0.0);
			    fixed NdotH2 = NdotH*NdotH;

			    fixed nom   = a2;
			    fixed denom = (NdotH2 * (a2 - 1.0) + 1.0);
			    denom = UNITY_PI * denom * denom;

			    return nom / denom;
			}

			fixed DistributionGGX(half nDotH, fixed roughness)
			{
			    fixed a      = roughness*roughness;
			    fixed a2     = a*a;

			    fixed NdotH2 = nDotH*nDotH;

			    fixed nom   = a2;
			    fixed denom = (NdotH2 * (a2 - 1.0) + 1.0);
			    denom = UNITY_PI * denom * denom;

			    return nom / denom;
			}

			fixed GeometrySchlickGGX(fixed nDotH, fixed roughness)
			{
			    fixed r = (roughness + 1.0);
			    fixed k = (r*r) / 8.0;

			    fixed nom   = nDotH;
			    fixed denom = nDotH * (1.0 - k) + k;

			    return nom / denom;
			}


			half geometric(half nDotV, half nDotL, half roughness)
			{
				//half k = roughness * roughness;
				//half k = 0.5 + roughness * 0.5;k *= k;
				half k = roughness * roughness * 0.5;
				half l = nDotL * (1.0 - k) + k;
				half v = nDotV * (1.0 - k) + k;
				return 0.25 / (l * v + 0.00001);
			}

			fixed GeometrySmith(half nDotV, half nDotL, half roughness)
			{
			    fixed ggx2  = GeometrySchlickGGX(nDotV, roughness);
			    fixed ggx1  = GeometrySchlickGGX(nDotL, roughness);

			    return ggx1 * ggx2;
			}

			half3 envir_brdf(half3 specularColor, half roughness, half nDotV)
			{
				const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
				const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
				half4 r = roughness * c0 + c1;
				half a004 = min(r.x * r.x, exp2(-9.28 * nDotV)) * r.x + r.y;
				half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
				return specularColor * AB.x + AB.y;// * 0.35;
			}

			half3 envir_brdf_nonmetal(half roughness, half nDotV)
			{
				const half2 c0 = { -1, -0.0275 };
				const half2 c1 = { 1, 0.0425 };
				half2 r = roughness * c0 + c1;
				return min(r.x * r.x, exp2(-9.28 * nDotV)) * r.x + r.y;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				half3 tangent = normalize(i.tangent);
				half3 binormal = normalize(i.binormal);
				half3 lightDir = normalize(i.lightDir);
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
				half4 m = tex2D(_MappingTex, uv); //粗糙度和金属度图
				half nDotL = dot(normal, lightDir);

				half atten = 1;

				half3 sssAlbedo = saturate(albedo - max(max(max(albedo.x, albedo.y), albedo.z) - 0.39, 0.1));
				// half sss = clamp(m.y * 2 - 1, 0, 1);
				half sss = m.y;
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
				half3 sh = ShadeSH9(n);

				//漫反射 
				diffuse += albedo * (1 - metallic) * ((nDotL + s1) * _LightColor + (envShadow * sh + s2 * sh));		
					
				// return 	float4(diffuse,1);
				half3 base = lerp(albedo, 0.04, 1 - metallic);
				half3 F = f_schlick(base, vDotH)*_FresnelValue;
				float D = d_ggx(roughness, nDotH);
				// float D = DistributionGGX(nDotH, roughness);
				half G = geometric(nDotV, nDotL, roughness);
				// half G = GeometrySmith(nDotV, nDotL, roughness);
				// specular += D * F * G * nDotL * _LightColor;
				specular += D * F / (4.0 * max(nDotV, 0.0) * max(nDotL, 0.0) + 0.001);
				half4 envir = texCUBElod(_EnvCubeMap, half4(refDir, int(roughness * 8)));
				envir.rgb *= envir.a;
                
				// diffuse += (1-F)*(1-metallic)*albedo;	
				//高光
				// specular += lerp(0.6, 1, nDotL) * envir * envir_brdf(base, roughness, nDotV) * envShadow;
				specular += lerp(0.6, 1, nDotL) * envir * envir_brdf(base, roughness, nDotV) * envShadow;
                // return float4(diffuse+specular,1);
				half aoValue = normalColor.z;
				half ao = lerp(lerp(1, aoValue, nDotV), aoValue, 2 * saturate(0.5 - aoValue));
				half3 finalColor = (diffuse + specular) * ao;
				finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
				finalColor += _Emission * _EmissionFactor * (1 - normalColor.w);
				return half4(finalColor * _Color.rgb, 1 + max(_Color.a, (1 - m.w)));


				
				// float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

				// fixed4 albedo = tex2D(_Albedo, i.uv);//采样固有色贴图

				// //获得切线坐标下的法线
				// fixed3 normal = UnpackNormal(tex2D(_Normal, i.uv));
				// //应用缩放，并计算出z分量的值
				// normal.xy *= _BumpScale;
				// normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
				// //将法线转换到世界坐标
				// normal = normalize(half3(dot(i.TtoW0.xyz, normal), dot(i.TtoW1.xyz, normal), dot(i.TtoW2.xyz, normal)));

				// normal = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));

				// fixed4 Metalness = tex2D(_MetalnessMap, i.uv);//采样金属度贴图

				// fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));//视角方向

				// //fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);//灯光方向
				// fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));

				// fixed3 halfDir = normalize(viewDir + lightDir);//half方向

				// fixed3 reflectDir = normalize(reflect(-viewDir,normal));//反射方向
				// fixed3 reflection = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflectDir,_Roughness*5).rgb;//反射目标

				// fixed3 F0 = lerp(fixed3(0.04,0.04,0.04), albedo, _Metalness);//金属与非金属的区别
				// fixed3 fresnel  = fresnelSchlick(max(dot(normal, viewDir), 0.0), F0);//菲涅尔项

				// fixed NDF = DistributionGGX(normal, halfDir, _Roughness);//Cook-Torrance 的d项

				// fixed G = GeometrySmith(normal, viewDir, lightDir, _Roughness);//Cook-Torrance 的g项

				// fixed3 specular = NDF * G * fresnel / (4.0 * max(dot(normal, viewDir), 0.0) * max(dot(normal, lightDir), 0.0) + 0.001);//反射部分 ps：+0.001是为了防止除零错误

				// specular += lerp(specular,reflection,fresnel);

				// fixed3 kD = (1.0 - fresnel) * (1.0 - _Metalness);//diffuse部分系数

				// float4 sh = float4(ShadeSH9(half4(normal,1)),1.0);
     
    			// fixed3 Final = (kD * albedo + specular) * _LightColor0.xyz * ( max(dot(normal, lightDir), 0.0) + 0.0);//反射及diffuse部分整合

    			// return  1;//补个环境反射的光
			}
			ENDCG
		}
		
	}
}
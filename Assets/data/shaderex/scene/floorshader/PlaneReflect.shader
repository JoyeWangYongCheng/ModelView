// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "TA_Test/PlaneReflect"
{
	Properties
	{
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "grey" {}
		_MappingTex("Mapping Texture", 2D) = "grey" {}

		_EnvShadowColor("Enviroument Shadow Color", Color) = (0.670588, 0.55294, 0.768627, 1.0)

		_ReflectionTex("_ReflectionTex", 2D) = "black" {}
		_ReflectionFactor("ReflectionFactor",Range(0.0, 3.0)) = 1.0

		_FogFactor("FogFactor",Range(0.0, 10.0)) = 1.0

		_fadeUVFactor("FadeUVFactor",Range(0.0, 5.0)) = 1.0
		_fadeAddColor("FadeAddColor",Color) = (1.0, 1.0, 1.0, 1.0)
		_fadeAddTime("FadeAddTime",Range(0.0, 5.0)) = 0.1
		_IndirectDiffuseFactor("IndirectDiffuseFactor",Range(0.0, 10.0)) = 1.0
		_IndirectSpecFactor("IndirectSpecFactor",Range(0.0, 10.0)) = 1.0
	}
	SubShader
	{
		// No culling or depth
		//Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
			};

			struct v2f
			{
				float2 mainUV : TEXCOORD0;
				float4 mappingUV:TEXCOORD6;
				float4 vertex : SV_POSITION;
				float4 screenPos:TEXCOORD1;
				float3 normalWorld:TEXCOORD2;
				float3 worldPos:TEXCOORD3;
				float3 tangent:TEXCOORD4;
				float3 binormal:TEXCOORD5;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			sampler2D _MappingTex;
			float4 _MappingTex_ST;

			float4 _EnvShadowColor;
			sampler2D _ReflectionTex;
			float _ReflectionFactor;

			float _fadeUVFactor;
			float4 _fadeAddColor;
			float _fadeAddTime;
			float _IndirectDiffuseFactor;

			sampler2D _FadeTex;
			float _CurFadeTime;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.mainUV = v.uv*_MainTex_ST.xy+_MainTex_ST.zw;
				o.mappingUV.xy = v.uv*_BumpMap_ST.xy + _BumpMap_ST.zw;
				o.mappingUV.zw = v.uv*_MappingTex_ST.xy + _MappingTex_ST.zw;
				o.screenPos = ComputeScreenPos(o.vertex);
				o.normalWorld = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
				float vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
				o.binormal = cross(o.tangent, o.normalWorld) * vv * v.tangent.w;
				return o;
			}
			


			// normal should be normalized, w=1.0
			half3 SHEvalLinearL0L1_00(half4 normal) {
				half3 x;
				fixed4 unity_SHAr = fixed4(-0.69, 0.79, -0.52, 0.87);
				fixed4 unity_SHAg = fixed4(-0.69, 0.86, -0.47, 0.93);
				fixed4 unity_SHAb = fixed4(-0.6, 0.96, -0.39, 1);

				// Linear (L1) + constant (L0) polynomial terms
				x.r = dot(unity_SHAr, normal);
				x.g = dot(unity_SHAg, normal);
				x.b = dot(unity_SHAb, normal);

				return x;
			}

			// normal should be normalized, w=1.0
			half3 SHEvalLinearL2_00(half4 normal) {
				half3 x1, x2;
				fixed4 unity_SHBr = fixed4(-0.87, -0.56, -0.23, 0.51);
				fixed4 unity_SHBg = fixed4(-0.81, -0.54, -0.23, 0.46);
				fixed4 unity_SHBb = fixed4(-0.67, -0.45, -0.23, 0.4);
				fixed4 unity_SHC = fixed4(-0.077, -0.068, -0.087, 1);
				// 4 of the quadratic (L2) polynomials
				half4 vB = normal.xyzz * normal.yzzx;
				x1.r = dot(unity_SHBr, vB);
				x1.g = dot(unity_SHBg, vB);
				x1.b = dot(unity_SHBb, vB);

				// Final (5th) quadratic (L2) polynomial
				half vC = normal.x * normal.x - normal.y * normal.y;
				x2 = unity_SHC.rgb * vC;

				return x1 + x2;
			}

			// normal should be normalized, w=1.0
			// output in active color space
			half3 LMDShadeSH9(half4 normal) {
				// Linear + constant polynomial terms
				half3 res = SHEvalLinearL0L1_00(normal);

				// Quadratic polynomials
				res += SHEvalLinearL2_00(normal);

				if (IsGammaSpace())
					res = LinearToGammaSpace(res);

				return res;
			}
			float sg(float t, float a)
			{
				float aa = a * a;
				return aa * aa * a;
				// return pow(a, t);
				//float k = t * 1.442695f + 1.089235f;
				//return exp2(k * a - k);
			}


			float3 f_schlick(float3 f0, float vDotH)
			{
				return f0 + (1 - f0) * sg(5, 1 - vDotH);
			}

			float d_ggx(float roughness, float nDotH)
			{
				float a = roughness * roughness;
				float a2 = a * a;
				float d = (nDotH * a2 - nDotH) * nDotH + 1;
				//return min(10000, a2 / (d * d + 0.00001) * INV_PI); 
				return min(10000, a2 / (d * d + 0.00001));
			}

			float geometric(float nDotV, float nDotL, float roughness)
			{
				//float k = roughness * roughness;
				//float k = 0.5 + roughness * 0.5;k *= k;
				float k = roughness * roughness * 0.5;
				float l = nDotL * (1.0 - k) + k;
				float v = nDotV * (1.0 - k) + k;
				return 0.25 / (l * v + 0.00001);
			}

			fixed3 envir_brdf_nonmetal(fixed roughness, fixed nDotV)
			{
				const fixed2 c0 = { -1, -0.0275 };
				const fixed2 c1 = { 1, 0.0425 };
				fixed2 r = roughness * c0 + c1;
				return min(r.x * r.x, exp2(-9.28 * nDotV)) * r.x + r.y;
			}

			fixed3 CalFadedAlbedoColor(fixed3 oriAlbedo, fixed2 uv)
			{
				fixed3 fadeColor = tex2D(_FadeTex, uv * _MainTex_ST.xy + _MainTex_ST.zw).rgb;
				fixed fadeA = tex2D(_FadeTex, uv * _fadeUVFactor).a;

				fixed a = step(fadeA, _CurFadeTime);

				fixed fadeFactor = saturate((_CurFadeTime - fadeA) / _fadeAddTime);
				fadeColor.rgb = lerp(_fadeAddColor.rgb, fadeColor.rgb, fadeFactor);
				fadeColor.rgb = lerp(oriAlbedo.rgb, fadeColor.rgb, fadeFactor);

				return oriAlbedo.rgb * (1 - a) + fadeColor.rgb * a;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 tangent = normalize(i.tangent);
				float3 binormal = normalize(i.binormal);
				float4 normalColor = tex2D(_BumpMap, i.mappingUV.xy);
				normalColor.xy = normalColor.xy * 2 - 1;
				float3 normalOffset = normalColor.x * tangent + normalColor.y * binormal;
				float3 normal = normalize(normalize(i.normalWorld) + normalOffset);

				float3 lightDir = 0;//normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				float3 viewDir = normalize(UnityWorldSpaceViewDir(normal));
				float nDotV = saturate(dot(normal, viewDir));
				float nDotL = saturate(dot(normal, lightDir));
				//float3 halfDir = normalize(lightDir + viewDir);
				//float nDotH = saturate(dot(normal, halfDir));
				//float vDotH = saturate(dot(viewDir, halfDir));

				float4 albedo = tex2D(_MainTex, i.mainUV * _MainTex_ST.xy + _MainTex_ST.zw);

				albedo.rgb = CalFadedAlbedoColor(albedo.rgb, i.mainUV);
				
				albedo = albedo * albedo;
				float4 mappingInfo = tex2D(_MappingTex, i.mappingUV.zw * _MappingTex_ST.xy + _MappingTex_ST.zw);
				float roughness = lerp(0.04, 1, saturate(mappingInfo.z));
				float metallic = mappingInfo.x;

				float3 finalColor = 0;
				//float3 diffuse = albedo * (1 - metallic) * nDotL;
				//float3 base = lerp(albedo, 0.04, 1 - metallic);
				//float3 F = f_schlick(base, vDotH);
				//float D = d_ggx(roughness, nDotH);
				//float G = geometric(nDotV, nDotL, roughness);
				//float3 specular = D * F * G * (nDotL );
				//finalColor += diffuse + specular;
				
				float3 sh = LMDShadeSH9(float4( normal,1));
				finalColor += albedo * (1 - metallic)*sh  * _IndirectDiffuseFactor;
				//return float4(sh, 1);
				
				float3 envShadow = lerp(_EnvShadowColor, 1, nDotL);

				float2 uvxy = (i.screenPos.xy / i.screenPos.w);
				float4 envir = tex2Dlod(_ReflectionTex, float4(uvxy, int(roughness * 8), int(roughness * 8))) * _ReflectionFactor;
				finalColor += lerp(0.6, 1, nDotL) * envir * envir_brdf_nonmetal(roughness, nDotV) * envShadow;

				//return fixed4(finalColor, 1);

				finalColor = finalColor / (finalColor + 0.187f) * 1.035f;
				return fixed4(finalColor,1);
			}
			ENDCG
		}
	}
}

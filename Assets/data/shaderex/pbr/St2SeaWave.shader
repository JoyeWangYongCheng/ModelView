// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "LMD/St2SeaWave" {
	Properties{
		_WaterColor("WaterColor", Color) = (0, 0, 0.8, 1)
		_BumpTex("BumpTex", 2D) = "bump" {}
		_WaterSpeed("WaterSpeed", float) = 0.74  //海水速度
		_Refract("Refract", float) = 0.07
		_Specular("Specular", float) = 1.86
		_Gloss("Gloss", float) = 0.71
		_SpecColor("SpecColor", Color) = (1, 1, 1, 1)

		_LightColor("LightColor",Color) = (1, 1, 1, 1)
		_LightDir("LightDir",Vector) = (0, -0.2,-1,	1)

		_FogColor("Fog Color",Color) = (1,1,1,1)
		_FogFactor("Fog Factor",Range(0,1)) = 0


		_ReflectOffectFactor("ReflectOffect",Range(0,1)) = 0
		_ReflectionTex("_ReflectionTex", 2D) = "black" {}
		_ReflectionFactor("ReflectionFactor",Range(0.0, 1.0)) = 1.0

    
		[Toggle] USE_GRAB("USE_GRAB", Float) = 0
		[Toggle] USE_WAVE("USE_WAVE", Float) = 1
		[Toggle] REALTIME_REFLECTION("REALTIME_REFLECTION", Float) = 0
		[Toggle] USE_REFLECTION("USE_REFLECTION", Float) = 0
	}

		SubShader{
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
			LOD 150

			zwrite off

			CGPROGRAM
			#pragma surface surf WaterLight noforwardadd vertex:vert alpha noshadow finalcolor:Fog
			#pragma multi_compile __ USE_REFLECTION_ON
			//#include "LMDCommon.cginc"
			#include "UnityCG.cginc"

			fixed4 _WaterColor;
			fixed4 _LightColor;
			half4 _LightDir;

			sampler2D _BumpTex;

			half _WaterSpeed;
			half _Refract;
			fixed _Specular;
			half _Gloss;

			half st2BlackFactor;
			fixed4 _FogColor;
			fixed  _FogFactor;
			sampler2D _ReflectionTex;
			float _ReflectionFactor;
			float _ReflectOffectFactor;

			float4 _ReflectionTex_ST;
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
				half fogFactor = exp2(-_FogFactor * z);
				fogFactor = clamp(fogFactor, 0.0, 1.0);
				return fogFactor;
			}

			//CGINCLUDE 
			fixed4 LightingWaterLight(SurfaceOutput s, half3 lightDir, half3 viewDir, fixed atten)
			{
				lightDir = -_LightDir.xyz;
				half3 halfVector = normalize(lightDir + viewDir);
				fixed diffFactor = max(0, dot(lightDir, s.Normal)) * 0.8 + 0.2;
				half nh = max(0, dot(halfVector, s.Normal));
				half spec = pow(nh, s.Specular * 128.0) * s.Gloss;
				fixed4 c;

				fixed3 diffuse = s.Albedo * _LightColor.rgb * diffFactor;

				c.rgb = (diffuse + _SpecColor.rgb * spec * _LightColor.rgb); //* (atten);

				//c.a = s.Alpha + spec * _SpecColor.a;
				c.a = s.Alpha;

				return c;
			}
			//ENDCG

			struct Input {
				//float2 uv_WaterTex;
				//float2 uv_NoiseTex;
				//float4 proj;
				//float3 viewDir;

				half2 uv_BumpTex;
				half fog;
				float4 screenPos;
			};

			inline void Fog(Input IN, SurfaceOutput o, inout fixed4 color)
			{
				color.rgb = lerp(_FogColor, color, saturate(IN.fog)) * (1 - st2BlackFactor);
			}

			void vert(inout appdata_full v, out Input i) {
				UNITY_INITIALIZE_OUTPUT(Input, i);

				half4 pos = UnityObjectToClipPos(v.vertex);
				i.fog = SimulateFog(pos);
			#ifdef USE_REFLECTION_ON
				i.screenPos = ComputeScreenPos(v.vertex);
			#endif
				//COMPUTE_EYEDEPTH(i.proj.z);
			}

			void surf(Input IN, inout SurfaceOutput o)
			{
				half4 offsetColor = (tex2D(_BumpTex,
					IN.uv_BumpTex + half2(_WaterSpeed*_Time.x, 0)) + tex2D(_BumpTex, half2(1 - IN.uv_BumpTex.y, IN.uv_BumpTex.x) + half2(_WaterSpeed*_Time.x, 0))) / 2;
				
			#if 0
				half2 offset = UnpackNormal(offsetColor).xy * _Refract;
				half4 bumpColor = (tex2D(_BumpTex,
					IN.uv_BumpTex + offset + half2(_WaterSpeed*_Time.x, 0)) + tex2D(_BumpTex, half2(1 - IN.uv_BumpTex.y, IN.uv_BumpTex.x) + offset + half2(_WaterSpeed*_Time.x, 0))) / 2;
				o.Normal = UnpackNormal(bumpColor).xyz;
			#else
				o.Normal = UnpackNormal(offsetColor).xyz;
			#endif

				o.Specular = _Specular;
				o.Gloss = _Gloss;
			#ifdef USE_REFLECTION_ON
				float2 uvxy = (IN.screenPos.xy / IN.screenPos.w);

				uvxy.xy = uvxy.xy * _ReflectionTex_ST.xy + _ReflectionTex_ST.zw;

				float4 envir =  tex2D(_ReflectionTex, saturate( lerp(float2(uvxy),offsetColor.xy , _ReflectOffectFactor)));
				o.Albedo = lerp(_WaterColor,  envir.xyz, _ReflectionFactor);

			#else
				o.Albedo = _WaterColor.rgb;
			#endif
				o.Alpha = 1;//min(_Range.x, deltaDepth) / _Range.x;
			}
			ENDCG
		}
			//FallBack "Diffuse"
}

Shader "LMD/Scene/Diffuse_TreeAnimation"
{
	Properties
	{
		_Color ("Main Color", Color) = ( 1, 1, 1, 1)
	    _ColorMultiplier("Color Multipler",range(0,2)) = 1
		_MainTex ("Texture", 2D) = "white" {}
		_LightIntensity("Light Intensity",Range(0,1))=1
		_Fog("Fog Color", Color) = (1,1,1,1)
		_Factor("Factor", Range(0, 0.05)) = 0	
		
		_Amplitude("树干幅度",float)=2.3
		_Frequency("树干频率",float)=0.74
		_Amplitude01("树叶幅度",float)=1
		_Frequency01("树叶频率",float)=1
        _WindDir("风向",Vector)=(1,1,1)
		_Cutoff("剔除",Range(0,1))=1					
	}
	SubShader
	{
        Tags { "RenderType" = "Opaque" }
        LOD 150
		// Cull Front
		CGPROGRAM
		#pragma surface surf Battle noforwardadd vertex:vert finalcolor:Fog

		sampler2D _MainTex;
		half4 _Color;
		half _ColorMultiplier;
		half _LightIntensity;
		uniform half st2BlackFactor;
		half4 _Fog;
		half _Factor;

        half _Amplitude;
        half _Frequency;
        half _Amplitude01;
        half _Frequency01;		
        half4 _WindDir;
        half _Cutoff;			
        
		struct Input 
		{
			half2 uv_MainTex;
			half fog;
			float4 color:COLOR;
		};
        //雾效
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
		//光照模型
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
		//光照Gi		
		inline void LightingBattle_GI(
			SurfaceOutput s,
			UnityGIInput data,
			inout UnityGI gi)
		{
			gi = UnityGlobalIllumination(data, 1.0, s.Normal);
		}
		//雾效
		inline void Fog(Input IN, SurfaceOutput o, inout fixed4 color)
        {
            color.rgb = lerp(_Fog, color, saturate(IN.fog)) * (1 - st2BlackFactor);
        }
		
		void vert (inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.fog = abs(v.normal);
			// half4 pos = UnityObjectToClipPos(v.vertex);
			
			
			float3 worldPos =mul(unity_ObjectToWorld,v.vertex).xyz;
            float4 offset;
			float phase = dot(worldPos.xz,0.1);
			offset.xz = cos(_Time.y*_Frequency+phase)*v.color.g*_Amplitude;
			offset.y = sin(_Time.y*_Frequency01+phase)*v.color.r*_Amplitude01;

			offset.xyz *= normalize(_WindDir);
			offset.w = 0;
			v.vertex+=offset;

	        half4 pos = UnityObjectToClipPos(v.vertex);
			o.fog = SimulateFog(pos);
//				o.uv = v.uv;
//				// o.color = v.color;
//				// o.color = fixed3(v.color.r,treeTrunk,v.color.b);			
		}	

		void surf(Input IN, inout SurfaceOutput o) {
			half4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color * _ColorMultiplier;
			clip(c.a-_Cutoff);
			// o.Albedo = o.color;
		}
			ENDCG

	}
}

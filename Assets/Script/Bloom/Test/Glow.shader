Shader "Hidden/Glow" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Bloom ("Bloom (RGB)", 2D) = "black" {}
	}
	
	CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		sampler2D _Bloom;
				
		uniform half4 _MainTex_TexelSize;
		half4 _MainTex_ST;
		
		uniform half4 _Parameter;
		
		#define ONE_MINUS_THRESHHOLD_TIMES_INTENSITY _Parameter.w

		struct v2f_simple 
		{
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;

        #if UNITY_UV_STARTS_AT_TOP
				half2 uv2 : TEXCOORD1;
		#endif
		};	
		
		v2f_simple vertBloom ( appdata_img v )
		{
			v2f_simple o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
        	o.uv = UnityStereoScreenSpaceUVAdjust(v.texcoord, _MainTex_ST);
        	
        #if UNITY_UV_STARTS_AT_TOP
        	o.uv2 = o.uv;
        	if (_MainTex_TexelSize.y < 0.0)
        		o.uv.y = 1.0 - o.uv.y;
        #endif
        	        	
			return o; 
		}
		
		fixed4 fragBloom ( v2f_simple i ) : SV_Target
		{	
			fixed4 color = tex2D(_MainTex, i.uv2);
			// return color;
			return color + tex2D(_Bloom, i.uv) * ONE_MINUS_THRESHHOLD_TIMES_INTENSITY;
		} 

		
		fixed4 fragDownsample ( v2f_simple i ) : SV_Target
		{				
			return tex2D (_MainTex, i.uv);
		}
	
		// weight curves
		static const half4 curve4[7] = { half4(0.0205,0.0205,0.0205,0), half4(0.0855,0.0855,0.0855,0), half4(0.232,0.232,0.232,0),
			half4(0.324,0.324,0.324,1), half4(0.232,0.232,0.232,0), half4(0.0855,0.0855,0.0855,0), half4(0.0205,0.0205,0.0205,0) };

		struct v2f_withBlurCoords8 
		{
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
			half2 offs : TEXCOORD1;
		};	

		v2f_withBlurCoords8 vertBlurHorizontal (appdata_img v)
		{
			v2f_withBlurCoords8 o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);
			o.offs = _MainTex_TexelSize.xy * half2(1.0, 0.0) * _Parameter.x;

			return o; 
		}
		
		v2f_withBlurCoords8 vertBlurVertical (appdata_img v)
		{
			v2f_withBlurCoords8 o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);
			o.offs = _MainTex_TexelSize.xy * half2(0.0, 1.0) * _Parameter.x;
			 
			return o; 
		}	

		half4 fragBlur8 ( v2f_withBlurCoords8 i ) : SV_Target
		{
			half2 uv = i.uv.xy; 
			half2 netFilterWidth = i.offs;  
			half2 coords = uv - netFilterWidth * 3.0;  
			
			half4 color = 0;
  			for( int l = 0; l < 7; l++ )  
  			{   
				half4 tap = tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(coords, _MainTex_ST));
				color += tap * curve4[l];
				coords += netFilterWidth;
  			}
			return color;
		}
					
	ENDCG
	
	SubShader {
	ZTest Off Cull Off ZWrite Off Blend Off
	
	// 0
	Pass {
		CGPROGRAM
		#pragma vertex vertBloom
		#pragma fragment fragBloom
		
		ENDCG
		 
		}
	
	// 1
	Pass {
		CGPROGRAM
		
		#pragma vertex vertBloom
		#pragma fragment fragDownsample
		
		ENDCG
		 
		}

	// 2
	Pass {
		Stencil
		{
			Ref 1
			Comp Equal
			Pass Keep
			ReadMask 1
			WriteMask 1
		}
		Cull Off
		
		CGPROGRAM 
		
		#pragma vertex vertBlurVertical
		#pragma fragment fragBlur8
		
		ENDCG 
		}
		
	// 3	
	Pass {
		Stencil
		{
			Ref 1
			Comp Equal
			Pass Keep
			ReadMask 1
			WriteMask 1
		}
		Cull Off
				
		CGPROGRAM
		
		#pragma vertex vertBlurHorizontal
		#pragma fragment fragBlur8
		
		ENDCG
		}	
	}	

	FallBack Off
}

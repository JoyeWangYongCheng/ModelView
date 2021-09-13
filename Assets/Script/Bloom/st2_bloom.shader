Shader "streetball2/bloom"
{
	Properties
	{
		_MainTex("", 2D) = "" {}
		_BaseTex("", 2D) = "" {}
		_BloomTex("", 2D) = "" {}
		_MaskTex("",2D)=""{}
	}

	CGINCLUDE

	#pragma target 3.0
	#include "UnityCG.cginc"

	#define BS  1
	#define GAU 2.5

	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	float4 _MainTex_ST;

	sampler2D _BaseTex;
	float2 _BaseTex_TexelSize;
	float2 _BaseTex_ST;

	sampler2D _MaskTex;
	float2 _MaskTex_TexelSize;
	float2 _MaskTex_ST;

	sampler2D _BloomTex;
	float2 _BloomTex_TexelSize;
	float2 _BloomTex_ST;

	float _Intensity;
	float _PrefilterOffs;
	float _Threshold;
	float3 _Curve;
	float _SampleScale;
	float _BlurSize;

	// -----------------------------------------------------------------------------
	// Tool
	#define HALF_MAX        65504.0

	inline half  SafeHDR(half  c) { return min(c, HALF_MAX); }
	inline half2 SafeHDR(half2 c) { return min(c, HALF_MAX); }
	inline half3 SafeHDR(half3 c) { return min(c, HALF_MAX); }
	inline half4 SafeHDR(half4 c) { return min(c, HALF_MAX); }

	half Brightness(half3 x)
	{
		return max(x.x, max(x.y, x.z));
	}

	half3 Median(half3 a, half3 b, half3 c)
	{
		return a + b + c - min(min(a, b), c) - max(max(a, b), c);
	}

	half4 DownsampleFilter(sampler2D tex, float2 uv, float2 texelSize)
	{
		float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);

		float4 s;
		s = (tex2D(tex, uv + d.xy));  
		s += (tex2D(tex, uv + d.zy));
		s += (tex2D(tex, uv + d.xw));
		s += (tex2D(tex, uv + d.zw));

		return s *0.25;
	}

	half4 UpsampleFilter(sampler2D tex, float2 uv, float2 texelSize, float sampleScale)
	{
		// 4-tap bilinear upsampler
		float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0) * (sampleScale);

		half4 s;
		s = (tex2D(tex, uv + d.xy));
		s += (tex2D(tex, uv + d.zy));
		s += (tex2D(tex, uv + d.xw));
		s += (tex2D(tex, uv + d.zw));

		return s * (1.0 / 4.0);
	}

	// -----------------------------------------------------------------------------
	// Vertex shaders
	struct AttributesDefault
	{
		float4 vertex : POSITION;
		float4 texcoord : TEXCOORD0;
	};

	struct VaryingsDefault
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uvSPR : TEXCOORD1; // Single Pass Stereo UVs
	};

	struct VaryingsMultitex
	{
		float4 pos : SV_POSITION;
		float2 uvMain : TEXCOORD0;
		float2 uvBase : TEXCOORD1;
		float2 uvMask : TEXCOORD2;
	};




	VaryingsDefault VertDefault(AttributesDefault v)
	{
		VaryingsDefault o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		o.uvSPR = UnityStereoScreenSpaceUVAdjust(v.texcoord.xy, _MainTex_ST);
		return o;
	}

	VaryingsMultitex VertMultitex(AttributesDefault v)
	{
		VaryingsMultitex o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uvMain = UnityStereoScreenSpaceUVAdjust(v.texcoord.xy, _MainTex_ST);
		o.uvBase = o.uvMain;
		o.uvMask = o.uvMain;

#if UNITY_UV_STARTS_AT_TOP
		if (_BaseTex_TexelSize.y < 0.0)
			o.uvBase.y = 1.0 - o.uvBase.y;
#endif
		return o;
	}

	// -----------------------------------------------------------------------------
	// Fragment shaders

	half4 FetchAutoExposed(sampler2D tex, float2 uv)
	{
		float autoExposure = 1.0;
		uv = UnityStereoScreenSpaceUVAdjust(uv, _MainTex_ST);
		return tex2D(tex, uv);
	}


	half4 FragDownsample(VaryingsDefault i) : SV_Target
	{
		return  DownsampleFilter(_MainTex, i.uvSPR, _MainTex_TexelSize.xy);
	}

	half4 FragUpsample(VaryingsMultitex i) : SV_Target
	{
		half4 color = tex2D(_BaseTex, i.uvBase);
		half4 blur =  UpsampleFilter(_MainTex, i.uvMain, _MainTex_TexelSize.xy, 1);
		return SafeHDR((color + blur));
	}
//高斯
half4 fragBlurVertical(VaryingsDefault i):SV_Target
{
	float weight[3]={0.4026,0.2442,0.0545};

	float2 uv = i.uv+float2(0.0,-_MainTex_TexelSize.y*2.0)*BS;
	float2 uv01 =  i.uv+float2(0.0,-_MainTex_TexelSize.y*1.0)*BS;
	float2 uv02 =  i.uv;
	float2 uv03 =  i.uv+float2(0.0,_MainTex_TexelSize.y*1.0)*BS;
	float2 uv04 =  i.uv+float2(0.0,_MainTex_TexelSize.y*2.0)*BS;

	fixed3 sum = tex2D(_MainTex,uv).rgb*weight[2];
	sum += tex2D(_MainTex,uv01).rgb*weight[1];
	sum += tex2D(_MainTex,uv02).rgb*weight[0];
	sum += tex2D(_MainTex,uv03).rgb*weight[1];
	sum += tex2D(_MainTex,uv04).rgb*weight[2];

 	half4 color = tex2D(_MainTex, i.uv);
   return fixed4(sum*GAU,1.0);
}
half4 fragBlurHorizontal(VaryingsDefault i):SV_Target
{
	float weight[3]={0.4026,0.2442,0.0545};

	float2 uv =  i.uv+float2(0.0,-_MainTex_TexelSize.x*2.0).yx*BS;
	float2 uv01 =  i.uv+float2(0.0,-_MainTex_TexelSize.x*1.0).yx*BS;
	float2 uv02 =  i.uv;
	float2 uv03 =  i.uv+float2(0.0,_MainTex_TexelSize.x*1.0).yx*BS;
	float2 uv04 =  i.uv+float2(0.0,_MainTex_TexelSize.x*2.0).yx*BS;



	fixed3 sum = tex2D(_MainTex,uv).rgb*weight[2];
	sum += tex2D(_MainTex,uv01).rgb*weight[1];
	sum += tex2D(_MainTex,uv02).rgb*weight[0];
	sum += tex2D(_MainTex,uv03).rgb*weight[1];
	sum += tex2D(_MainTex,uv04).rgb*weight[2];


//	return sum;	


 //  fixed3 sum = tex2D(_MainTex,i.uv).rgb*weight[0];
 //  float2 uv01 = uv+float2(0.0,_MainTex_TexelSize.y*1.0)*_BlurSize;
 //  fixed3 sum01 = tex2D(_MainTex,uv01).rgb*weight[0];
   return fixed4(sum*GAU,1.0);
}


	half4 FragCombine(VaryingsMultitex i) : SV_Target
	{
		half4 base = (tex2D(_MainTex, i.uvMain));
		half4 blur = (tex2D(_BloomTex, i.uvMain));
		//half4 maskTex = tex2D(_MaskTex,i.uvMask);
		//return blur;
		return SafeHDR(base+ blur);
	}

	ENDCG

	SubShader
	{
		ZTest Always Cull Off ZWrite Off
        
		Pass
		{
			CGPROGRAM
				#pragma vertex VertDefault
				#pragma fragment FragDownsample
			ENDCG
		}
//gauss
		pass
		{
			CGPROGRAM
				#pragma vertex VertDefault
				#pragma fragment fragBlurVertical
			ENDCG			
		}
		pass
		{
			CGPROGRAM
				#pragma vertex VertDefault
				#pragma fragment fragBlurHorizontal
			ENDCG			
		}

		Pass
		{
			CGPROGRAM
				#pragma vertex VertMultitex
				#pragma fragment FragUpsample
			ENDCG
		}

		Pass
		{
			CGPROGRAM
				#pragma vertex VertMultitex
				#pragma fragment FragCombine
			ENDCG
		}
	}
}

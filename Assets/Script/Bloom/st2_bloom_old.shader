Shader "streetball2/bloom_old"
{
	Properties
	{
		_MainTex("", 2D) = "" {}
		_BaseTex("", 2D) = "" {}
		_BloomTex("", 2D) = "" {}
	}

	CGINCLUDE

	#pragma target 3.0
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	float4 _MainTex_ST;

	sampler2D _BaseTex;
	float2 _BaseTex_TexelSize;
	float2 _BaseTex_ST;

	sampler2D _BloomTex;
	float2 _BloomTex_TexelSize;
	float2 _BloomTex_ST;

	float _Intensity;
	float _PrefilterOffs;
	float _Threshold;
	float3 _Curve;
	float _SampleScale;

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

		half4 s;
		s = (tex2D(tex, uv + d.xy));
		s += (tex2D(tex, uv + d.zy));
		s += (tex2D(tex, uv + d.xw));
		s += (tex2D(tex, uv + d.zw));

		return s * (1.0 / 4.0);
	}

	half4 UpsampleFilter(sampler2D tex, float2 uv, float2 texelSize, float sampleScale)
	{
		// 4-tap bilinear upsampler
		float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0) * (sampleScale * 0.5);

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

	half4 FragPrefilter(VaryingsDefault i) : SV_Target
	{
		float2 uv = i.uv + _MainTex_TexelSize.xy * _PrefilterOffs;

		// half4 s0 = SafeHDR(FetchAutoExposed(_MainTex, uv));
		half4 s0 = tex2D(_MainTex,i.uv);

		half3 m = s0.rgb;
        //叠加颜色， 让整体饱和度降低
		m *= m;
		// clamp(s0.a - 1, 0, 1) 把人物 shader  a通道的值加大，然后通过clamp把其余都抠掉，再乘以颜色  显示人物。
		m *= clamp(s0.a - 1, 0, 1);
		
		half br = Brightness(m);
		
		//提取整个人的亮度

		half r = max(br - _Threshold, 0);
		m *= r;
// return fixed4(m,s0.a);
		return SafeHDR(half4(m, s0.a));

			// 	fixed4 col = tex2D(_MainTex, i.uv);

			// 	// fixed shadeValue = clamp (col.a-1,0,1);
			// 	// return shadeValue;
            //     //得到提取后亮部区域
			// 	// fixed val = clamp(luminance(col.a)-_LuminanceThreshold,0.0,1.0);
			// 	// if(col.a>0.8)
			// 	// {
			// 	// 	col.a = 1;
			// 	// }else{
			// 	// 	col.a = 0 ;
			// 	// }
			// 	// return col;
			// 	half3 m = col.rgb;
			// 	m*=m;
			// 	m *= clamp((1- col.a)*14,0,1);

			// 	//提取亮度
			// 	half br = max(m.x,max(m.y,m.z));
			// 	// return br;
			// 	half r = max(br,0);
			// 	m*=r;
			// return fixed4(m,col.a);
	}

	half4 FragDownsample1(VaryingsDefault i) : SV_Target
	{
		return SafeHDR(DownsampleFilter(_MainTex, i.uvSPR, _MainTex_TexelSize.xy));
	}

	half4 FragDownsample2(VaryingsDefault i) : SV_Target
	{
		return SafeHDR(DownsampleFilter(_MainTex, i.uvSPR, _MainTex_TexelSize.xy));
	}

	half4 FragUpsample(VaryingsMultitex i) : SV_Target
	{
		half4 color = tex2D(_BaseTex, i.uvBase);
		half4 blur = UpsampleFilter(_MainTex, i.uvMain, _MainTex_TexelSize.xy, _SampleScale);
		return SafeHDR((color + blur));
	}

	half4 FragCombine(VaryingsMultitex i) : SV_Target
	{
		half4 base = (tex2D(_MainTex, i.uvMain));
		half4 blur = (tex2D(_BloomTex, i.uvMain));
		return SafeHDR(base + blur * _Intensity);
	}

	ENDCG

	SubShader
	{
		ZTest Always Cull Off ZWrite Off

		Pass
		{
			CGPROGRAM
				#pragma vertex VertDefault
				#pragma fragment FragPrefilter
			ENDCG
		}

		Pass
		{
			CGPROGRAM
				#pragma vertex VertDefault
				#pragma fragment FragDownsample1
			ENDCG
		}

		Pass
		{
			CGPROGRAM
				#pragma vertex VertDefault
				#pragma fragment FragDownsample2
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

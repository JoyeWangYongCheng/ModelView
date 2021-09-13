Shader "streetball2/scene_mirror_reflection" 
{
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		_MaskTex("Mask Tex", 2D) = "black" {}
		_ReflectionTex("Reflection Tex", 2D) = "white" {}
		_PlayerReflectTex("PlayerReflect Tex", 2D) = "black" {}
		_ReflectionIntensity("Reflection Intensity", Range(0.01,1.0)) = 0.1
	}
	SubShader
	{ 
		Tags { "RenderType" = "Opaque" }

		CGINCLUDE
		#include "UnityCG.cginc"

		float4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _ReflectionTex;
		sampler2D _PlayerReflectTex;
		half _ReflectionIntensity;
		sampler2D _MaskTex;
		uniform float st2BlackFactor;
		
		struct v2f
		{
			float4  pos : SV_POSITION;
			float2  uv : TEXCOORD0;
			float4 refl : TEXCOORD1;
		};

		v2f vert(appdata_base v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.refl = ComputeScreenPos(o.pos);
			return o;
		}

		ENDCG

		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragPlayer

			float4 fragPlayer(v2f i) : COLOR
			{
				fixed4 mask = tex2D(_MaskTex, i.uv);
				fixed4 refl = tex2Dproj(_PlayerReflectTex, UNITY_PROJ_COORD(i.refl));
				return refl*mask.r*_ReflectionIntensity;
			}
			ENDCG 
		}
		pass
		{
			Blend One   One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragBG

			float4 fragBG(v2f i) : COLOR
			{
				fixed4 color = tex2D(_MainTex, i.uv) * _Color;
				fixed4 mask = tex2D(_MaskTex, i.uv);

				fixed4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.refl));
				float factor = _ReflectionIntensity * mask.r;
				color.rgb = color.rgb * (1 - factor) + refl.rgb * factor;

				fixed alpha = _Color.a * (1 - color.a);
				color = color * (1 - st2BlackFactor);
				color.a = alpha;
				return color;
			}

			ENDCG
		}

	}
}
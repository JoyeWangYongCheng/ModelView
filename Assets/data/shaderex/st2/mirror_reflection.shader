// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/***
* 修改自 http://wiki.unity3d.com/index.php/MirrorReflection4
*/
Shader "fx/mirror_reflection"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		[HideInInspector] _ReflectionTex("", 2D) = "white" {}
		_ReflectionIntensity("Reflection Intensity", Range(0.01,1.0)) = 0.1
	}

	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 refl : TEXCOORD1;
				float4 pos : SV_POSITION;
			};

			float4 _MainTex_ST;

			v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(pos);
				o.uv = TRANSFORM_TEX(uv, _MainTex);
				o.refl = ComputeScreenPos(o.pos);
				return o;
			}

			sampler2D _MainTex;
			sampler2D _ReflectionTex;
			half _ReflectionIntensity;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 tex = tex2D(_MainTex, i.uv);
				fixed4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.refl));
				fixed4 col = tex * refl;
				col.a = _ReflectionIntensity;
				return col;
			}
			ENDCG
		}
	}
}

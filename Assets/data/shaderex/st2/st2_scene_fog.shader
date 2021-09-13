Shader "streetball2/scene_fog" 
{
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		_Fog("Fog Color", Color) = (1,1,1,1)
		_Factor("Factor", Range(0, 1)) = 0.003
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Blend One Zero, SrcAlpha Zero
		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			float4 _Color;
			float4 _MainTex_ST;
			float4 _Fog;
			float _Factor;

			uniform float st2BlackFactor;

			struct v2f
			{
				float4  pos : SV_POSITION; 
				float2  uv : TEXCOORD0; 
				float  fog : TEXCOORD1;
			};

			float SimulateFog(float4 pos)
			{
#if defined(UNITY_REVERSED_Z)
	#if UNITY_REVERSED_Z == 1
				float z = max(((1.0 - (pos.z) / _ProjectionParams.y)*_ProjectionParams.z), 0);
	#else
				float z = max(-(pos.z), 0);
	#endif
#elif UNITY_UV_STARTS_AT_TOP
				float z = pos.z;
#else
				float z = pos.z;
#endif
				float fogFactor = exp2(-_Factor * z);
				fogFactor = clamp(fogFactor, 0.0, 1.0);
				return fogFactor;
			}

			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.fog.x = SimulateFog(o.pos) ;
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed4 color = tex2D(_MainTex, i.uv) * _Color;
				fixed bloom = _Color.a * (1 - color.a);
				color = lerp(_Fog, color, saturate(i.fog)) * (1 - st2BlackFactor);
				color.a = bloom;
				return color;
			}

			ENDCG 
		}
	}

	FallBack Off
}
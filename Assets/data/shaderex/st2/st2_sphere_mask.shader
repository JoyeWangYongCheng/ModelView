Shader "streetball2/st2_sphere_mask"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Main Color", Color) = (1,1,1,1)
		_Center("Center", vector) = (0, 0, 0, 0)
		_Radius("Radius", Range(0, 3)) = 1
		_SmoothBorder("Smooth Border", Range(0, 2)) = 0
		[Toggle] _ZwriteOn("ZWrite On", Int) = 0
		_Value("value",float)=1
	}

	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite[_ZwriteOn]

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
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float4 localPos : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;

			float4 _Center;
			float _Radius;
			float _SmoothBorder;

			uniform float st2BlackFactor;
			float _Value;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.localPos = v.vertex;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//float3 delta = i.worldPos - _Center;
				float3 delta = i.localPos - _Center;

				float len = length(delta);
				float factor = 1 - smoothstep(_Radius - _SmoothBorder, _Radius + _SmoothBorder, len);

				fixed4 color = tex2D(_MainTex, i.uv) * _Color;
				color = color * factor * (1 - st2BlackFactor);
				return fixed4(color.rgb*_Value,color.a);
			}
			ENDCG
		}
	}
}

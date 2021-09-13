Shader "streetball2/basketball_net"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Main Color", Color) = (1,1,1,1)
	}
	
	SubShader
	{
		Tags{ "Queue" = "AlphaTest" }

		ColorMask RGB
		ZWrite On
		ZTest LEqual

		Cull Off

		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			float4 _Color;
			float4 _MainTex_ST;

			uniform float st2BlackFactor;

			struct v2f
			{
				float4  pos : SV_POSITION;
				float2  uv : TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				fixed4 color = tex2D(_MainTex, i.uv) * _Color;
				clip(color.a - 0.25);
				return color * (1 - st2BlackFactor);
			}

			ENDCG
		}
	}
}
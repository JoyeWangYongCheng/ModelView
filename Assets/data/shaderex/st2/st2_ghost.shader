Shader "streetball2/ghost"
{
	Properties 
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DiffTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Cull Off

		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			sampler2D _DiffTex;
			float4 _MainTex_ST;

			struct appdata_self
			{
				float4  vertex : POSITION; 
				float4  color : COLOR;
			};

			struct v2f
			{
				float4  pos : SV_POSITION; 
				float4  color : TEXCOORD1;
			};

			v2f vert (appdata_self v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed4 color = tex2D(_DiffTex, i.color.xy);
				color.a = tex2D(_MainTex, i.color.zw).r;
				return color;
			}

			ENDCG 
		}
	}
}
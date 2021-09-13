Shader "streetball2/ball_ghost"
{
	Properties 
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_GhostColor("GhostColor", Color) = (1,1,1,1)
		_LightDir("Light Direction", Vector) = (0.2,1,-0.4,0)
		_LightColor("Light Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Cull Back

		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex;			
			float4 _MainTex_ST;

			fixed4 _Color;
			fixed4 _GhostColor;
			fixed4 _LightDir;
			fixed4 _LightColor;

			struct appdata
			{
				float4  vertex : POSITION;
				float2  texcoord : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4  pos : SV_POSITION;
				float2  uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				half l = dot(i.normal, _LightDir);
				l = (l + 1) * 0.5;
				fixed4 color = tex2D(_MainTex, i.uv) * _Color * _LightColor * l;
				color.rgb *= _GhostColor.rgb;
				color.a = _GhostColor.a;
				return color;
			}

			ENDCG 
		}
	}
}
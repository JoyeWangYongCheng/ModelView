Shader "streetball2/alpha_texture_noztest" {
Properties {
	_MainTex ("Texture", 2D) = "white" {}
	_Color ("Main Color", Color) = (1,1,1,1)
}
SubShader
{
	Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

	Blend SrcAlpha OneMinusSrcAlpha, Zero Zero
	ZWrite off
	ZTest off

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
			float4  color : TEXCOORD1;
		};

		v2f vert (appdata_full v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.color = v.color;
			return o;
		} 

		float4 frag (v2f i) : COLOR
		{
			fixed4 color = tex2D(_MainTex, i.uv) * _Color * i.color;
			color.rgb *= (1 - st2BlackFactor);
			return color;
		}

		ENDCG 
		}
	}
}
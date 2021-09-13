Shader "streetball2/scene_alpha_no_cull"
{
	Properties 
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

		Blend SrcAlpha OneMinusSrcAlpha, Zero Zero
		ZWrite Off
		ZTest LEqual
		Cull Off

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

			struct v2f
			{
				float4  pos : SV_POSITION; 
				float2  uv : TEXCOORD0; 
				UNITY_FOG_COORDS(1)
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed4 color = tex2D(_MainTex, i.uv) * _Color;
				UNITY_APPLY_FOG(i.fogCoord, color);
				return color;
			}

			ENDCG 
		}
	}
}
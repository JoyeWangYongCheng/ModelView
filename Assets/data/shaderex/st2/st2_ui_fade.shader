Shader "streetball2/ui_fade" 
{
	Properties {
		_MainTex ("Main Texture", 2D) = "white" {}
		_BackupTex ("Backup Texture", 2D) = "white" {}
		_Factor("factor",Range(0,20)) = 0.01//描边粗细因子
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

		Blend One Zero
		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			sampler2D _BackupTex;
			float _Factor;

			struct v2f
			{
				float4  pos : SV_POSITION; 
				float2  uv : TEXCOORD0; 
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed4 c1 = tex2D(_MainTex, i.uv);
				fixed4 c2 = tex2D(_BackupTex, i.uv);
				return lerp(c2, c1, _Factor);
			}

			ENDCG 
		}
	}
}
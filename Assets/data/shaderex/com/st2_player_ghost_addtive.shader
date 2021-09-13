Shader "streetball2/player_ghost_addtive"
{
	Properties 
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_GhostColor("Ghost Color", Color) = (0.0745,0.78,0.8,1)
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType"="Transparent"}

		Blend One One
		Cull Back
		ZWrite Off

		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float4 _Color;
			float4 _GhostColor;

			struct v2f
			{
				float4  pos : SV_POSITION; 
				float2  uv : TEXCOORD0; 
				float3  normal : TEXCOORD1;
				float3  posWorld : TEXCOORD2;
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.normal = normalize(UnityObjectToWorldNormal(v.normal));
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
				fixed a = (1 - dot(viewDir, i.normal)) * _Color.a;
				a = a * a * 8;
				return fixed4(_GhostColor.rgb * a, a);
			}

			ENDCG 
		}
	}
}
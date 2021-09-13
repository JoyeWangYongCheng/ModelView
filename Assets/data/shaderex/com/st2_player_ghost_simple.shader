Shader "streetball2/player_ghost_simple"
{
	Properties
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_GhostColor("Ghost Color", Color) = (0.0745,0.78,0.8,1)
	}

	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType" = "Transparent"}

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back
		ZWrite Off
		ColorMask RGB

		pass
		{
			Stencil
			{
				Ref 0
				Comp Equal
				Pass IncrSat
				Fail Keep
			}

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
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				return fixed4(_GhostColor.rgb, _Color.a);
			}

			ENDCG
		}
	}
}
Shader "streetball2/emoji_ui Gray"
{
	Properties 
	{
		_MainTex("Sprite Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha, Zero Zero
		ColorMask[_ColorMask]

		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			sampler2D _MainTex;
			float4 _Color;
			float4 _ClipRect;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 color : COLOR;
				float2 uv  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				o.worldPosition = v.vertex;
				o.pos = UnityObjectToClipPos(v.vertex);
#ifdef UNITY_HALF_TEXEL_OFFSET
				o.pos += (_ScreenParams.zw - 1.0) * float2(-1, 1) * o.pos.w;
#endif
				fixed t = _Time.y * 6;          
				fixed c = floor(t / 2);
				fixed r = floor(t - c * 2);
				o.uv = v.texcoord * 0.49 + 0.005 + fixed2(fmod(0.5 * r, 1), fmod(0.5 * c, 1));
				return o;
			} 

			float4 frag (v2f i) : COLOR
			{
				fixed4 color = tex2D(_MainTex, i.uv) * _Color;
				color.rgb = dot(color.rgb, fixed3(0.3, 0.59, 0.11));
				color.a *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
				return color;
			}

			ENDCG 
		}
	}
}
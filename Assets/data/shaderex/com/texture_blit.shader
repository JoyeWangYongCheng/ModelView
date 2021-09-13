Shader "tools/texture_blit"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			float4 _SrcSpriteRect;		//源Sprite uv范围，xy最小点，zw最大点
			float4 _TargetRect;			//目标范围 xy最小点，zw最大点
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			//AABB矩形拷贝，将一张图拷贝到目标位置并进行缩小
			fixed4 frag(v2f i) : SV_Target
			{	
				//float4 _TargetRect = float4(0, 0, 1, 1);
				//float4 _SrcSpriteRect = float4(0, 0, 1, 1);

				float2 uvScale =  float2(1 /(_TargetRect.z - _TargetRect.x), 1 /(_TargetRect.w - _TargetRect.y));
				float2 uv = (i.uv  - _TargetRect.xy) * uvScale;
				uv = frac(uv);
				uv = lerp(_SrcSpriteRect.xy, _SrcSpriteRect.zw, uv); //uv插值

				fixed4 c = tex2D(_MainTex, uv);
				c.a *= UnityGet2DClipping(i.worldPos, _TargetRect);
				return c;
			}

			ENDCG
		}
	}
}

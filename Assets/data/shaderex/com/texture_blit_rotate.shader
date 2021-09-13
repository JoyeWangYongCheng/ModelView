// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "tools/texture_blit_rotate"
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

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

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
			float _TargetAngle;			//目标角度			

			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			float2 Rotate(float2 rotateCenter, float2 p, float degree)
			{
				p = p - rotateCenter;
				float rad = radians(degree);
				float x = p.x * cos(rad) - p.y * sin(rad);
				float y = p.x * sin(rad) + p.y * cos(rad);
				return float2(x, y) + rotateCenter;
			}

			//将一张图片拷贝到另外一张图片的 目标位置并进行旋转，
			//在Graphics.Blit中使用
			fixed4 frag(v2f i) : SV_Target
			{
				float minX = _TargetRect.x;
				float maxX = _TargetRect.z;
				float minY = _TargetRect.y;
				float maxY = _TargetRect.w;

				float2 center = float2(minX + maxX, minY + maxY) * 0.5;
				float2 worldPos0 = float2(minX, minY);
				float2 worldPos1 = float2(maxX, minY);
				float2 worldPos2 = float2(maxX, maxY);
				float2 worldPos3 = float2(minX, maxY);

				worldPos0 = Rotate(center, worldPos0, _TargetAngle);
				worldPos1 = Rotate(center, worldPos1, _TargetAngle);
				worldPos2 = Rotate(center, worldPos2, _TargetAngle);
				worldPos3 = Rotate(center, worldPos3, _TargetAngle);

				float2 pos = i.worldPos.xy;
				float2 deltaPos = pos - worldPos0;
				float2 uv = float2(0, 0);
				uv.x = dot(deltaPos, normalize(worldPos1 - worldPos0)); //新坐标系下的x
				uv.y = dot(deltaPos, normalize(worldPos3 - worldPos0)); //新坐标系下的y
				uv.x = uv.x / (maxX - minX); //转换到0~1，超过0~1的则在范围外
				uv.y = uv.y / (maxY - minY); //转换到0~1，超过0~1的则在范围外

				//区域裁剪
				fixed4 c = tex2D(_MainTex, lerp(_SrcSpriteRect.xy, _SrcSpriteRect.zw, uv));
				c.a *= UnityGet2DClipping(uv, float4(0, 0, 1, 1));

				return c;
			}

			ENDCG
		}
	}

	Fallback Off
}

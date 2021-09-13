Shader "TA_Test/UIEffect/ShineAdditive"
{
	Properties
	{
        [PerRendererData]_MainTex ("Base (RGB)", 2D) = "white" {}
        _FlashColor ("Flash Color", Color) = (1,1,1,1)
        _Angle ("Flash Angle", Range(0, 180)) = 45
        _Width ("Flash Width", Range(0, 1)) = 0.2
        _LoopTime ("Loop Time", Float) = 1   //闪光条滚动一次的时间
        _Interval ("Time Interval", Float) = 3   //两次相邻的闪光条滚动的时间间隔
		[Toggle] _DISPERSE ("Is Dispersed", Float) = 0 
        _Reverse("Reverse",Range(-1,1))=1
		// _Boundary("Dispersed Boundary", Float) = 0.5
	}
	SubShader
	{

        Tags { "Queue"="Transparent" "RenderType"="Transparent" }	
		ZWrite Off
		//Blend SrcAlpha OneMinusSrcAlpha
		Blend SrcAlpha One
		ColorMask RGB

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _DISPERSE_ON
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

        sampler2D _MainTex;
		// fixed _MainTexFactor;
        fixed4 _FlashColor;
		float _Angle;
		float _Width;
		float _LoopTime;
		float _Interval;
		float _Reverse;
        // fixed _Boundary;


			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
        fixed InFlash(half2 uv)
        {	
            half brightness = 0;
			float angleInRad = 0.0174444 * _Angle;
			float tanInverseInRad = 1.0 / tan(angleInRad);

            //设置当前时间
            float currentTime = _Time.y;

            //全部时间  间隔时间+滚动一次的时间  2+1 =3
			float totalTime = _Interval + _LoopTime;
            //当前转动开始的时间 = 当前时间/全部时间 * 全部时间   (int)(1/3)*3 = 0
			float currentTurnStartTime = (int)((currentTime / totalTime)) * totalTime;
			// 当前转动结束的时间 =  当前时间 - 当前开始时间 - 间隔时间   1 - 0 - 2 = -1
			float currentTurnTimePassed = currentTime - currentTurnStartTime - _Interval;
			//百分比 = 当前结束时间/滚动一次的时间  -1/1 =-1
			float percent = currentTurnTimePassed / _LoopTime*_Reverse;

            bool onLeft = (tanInverseInRad > 0);
			float xBottomFarLeft = onLeft? 0.0 : tanInverseInRad;
			float xBottomFarRight = onLeft? (1.0 + tanInverseInRad) : 1.0;
			float xBottomRightBound = xBottomFarLeft + percent* (xBottomFarRight - xBottomFarLeft);
			float xBottomLeftBound = xBottomRightBound - _Width;
			float xProj = uv.x + uv.y * tanInverseInRad;
            
			//剔除不需要的像素 
            if(xProj > xBottomLeftBound && xProj < xBottomRightBound)
            {
              	brightness = 1.0 - abs(2.0 * xProj - (xBottomLeftBound + xBottomRightBound)) / _Width;
            }

            return brightness;
        }

		fixed CalHalfBrigthness(bool onLeft,fixed tanInverseInRad,fixed xProj,fixed percent)
		{
			half brightness = 0;
			float xlBottomFarLeft = onLeft? 0.0 : tanInverseInRad;
			float xlBottomFarRight = onLeft? (1.0 + tanInverseInRad) : 1.0;

			float xlBottomRightBound = xlBottomFarLeft + percent * (xlBottomFarRight - xlBottomFarLeft);
			float xlBottomLeftBound = xlBottomRightBound - _Width;
			
			if(xProj > xlBottomLeftBound && xProj < xlBottomRightBound)
			{
				brightness = 1.0 - abs(2.0 * xProj - (xlBottomLeftBound + xlBottomRightBound)) / _Width;
			}
			
			return brightness;
		}

		fixed HalfInFlash(half2 uv)
		{
			half brightness = 0;
			half _Boundary = 0.5;
			 float angleInRad = 0.0174444 * _Angle;
			 float tanInverseInRad = 1.0 / tan(angleInRad);

            float currentTime = _Time.y ;

			float totalTime = _Interval + _LoopTime;
			float currentTurnStartTime = (int)((currentTime / totalTime)) * totalTime;
			float currentTurnTimePassed = currentTime - currentTurnStartTime - _Interval;
			
			if(currentTurnTimePassed > 0)
			{
				half percent = currentTurnTimePassed / _LoopTime;
				bool onLeft = (tanInverseInRad > 0);
				
				//fixed boundary = 0.35;
				
				float xProj;
				if(uv.x >= 0.0 && uv.x <= _Boundary)
				{
					xProj = uv.x + uv.y * tanInverseInRad;
					brightness = CalHalfBrigthness(onLeft,tanInverseInRad,xProj,1 - percent);
				}
				else if(uv.x > _Boundary && uv.x <= 1.0)
				{
					//tanInverseInRad = 1.0 / tan(180 * 0.0174444 - angleInRad);
					//onLeft = (tanInverseInRad > 0);
					xProj = _Boundary - (uv.x - _Boundary) + uv.y * tanInverseInRad;
					brightness = CalHalfBrigthness(onLeft,tanInverseInRad,xProj,1 - percent);
				}
			}

            return brightness;
		}		

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 texCol = tex2D(_MainTex, i.uv);
				fixed brightness = InFlash(i.uv);

                #ifdef _DISPERSE_ON
				  brightness = HalfInFlash(i.uv);
				#endif
				fixed3 finish = _FlashColor.rgb;
				
				//clip(texCol.a * _FlashColor.a * brightness - 0.1);

                return fixed4(finish,texCol.a * _FlashColor.a*brightness);
			}
			ENDCG
		}
	}
}

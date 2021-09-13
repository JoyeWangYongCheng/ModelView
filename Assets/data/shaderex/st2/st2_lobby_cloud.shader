Shader"streetball2/lobby_cloud"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _Color ("Tint", Color) = (1, 1, 1, 1)
        _Velocity ("Velocity", Range(-2, 2)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent" 
            "RenderType"="Transparent"
        }

        Cull Off
        ZWrite Off
        Blend SrcAlpha One

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

            sampler2D _MainTex;
            float _Velocity;
            fixed4 _Color;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            v2f vert(appdata i)
            {
                v2f o;
				o.vertex = UnityObjectToClipPos(i.vertex);
				o.texcoord = i.texcoord;
                o.texcoord.x += _Time.x * _Velocity;
                o.color = i.color * _Color;
				return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.texcoord) * i.color;
            }
            ENDCG
        }
    }
}
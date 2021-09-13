// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "streetball2/distortion" {
Properties {
    _MainTex ("Main Texture", 2D) = "white" {}
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
    Blend SrcAlpha OneMinusSrcAlpha
    // ColorMask RGB
    //Cull Off 
    Lighting Off 
    ZWrite Off
    ZTest Always
    
    SubShader {
    
		// GrabPass
		// {
		// 	//此处给出一个抓屏贴图的名称，抓屏的贴图就可以通过这张贴图来获取，而且每一帧不管有多个物体使用了该shader，只会有一个进行抓屏操作
		// 	//如果此处为空，则默认抓屏到_GrabTexture中，但是据说每个用了这个shader的都会进行一次抓屏！
		// 	"_GrabTempTex"
		// }   

        Pass {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_particles
            #pragma multi_compile_fog
            #pragma multi_compile __ _DISTORTONLY_ON

            #include "UnityCG.cginc"



            struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };
            sampler2D _MainTex;
            
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
			sampler2D _GrabTempTex;
			float4 _GrabTempTex_ST;

            fixed4 _TintColor;
            float _Intensity;
            float _SamplingRange;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                 //return tex2D(_GrabTempTex,i.texcoord);
                // return float4(0,1,0,1);
                // return fixed4(i.texcoord,0,1);
                float4 _GrabColor = tex2D(_GrabTempTex,i.texcoord)*10;
                // return fixed4(_GrabColor.rrr,1);
                return   tex2D(_MainTex,i.texcoord+(saturate(_GrabColor.r)*_MainTex_TexelSize.xy*20)*_Intensity);
            }
            ENDCG
        }
    }
}
}

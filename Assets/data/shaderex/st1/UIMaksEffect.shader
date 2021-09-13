// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/UIMaskEffect"
{
    Properties
    {
        // [PerRendererData] 
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _MaskTex("Mask Texture",2D) = "white"{}
        _Color ("Tint", Color) = (1,1,1,1)
        _Threshold("Threshold",Range(0,1)) = 1
        _MainTexOpaque("Main Texture Opaque",Range(0,1)) =  1
        _BackGroundColor("BG Color",color) = (1,1,1,1)
        _MaskColor("Mask Color",color) = (1,1,1,1)

        _TileCount("Tile Count",float) = 8
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }


        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
      	    CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color,_BackGroundColor,_MaskColor;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            half _MainTexOpaque;
            float _Threshold,_TileCount;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = v.texcoord;

                OUT.color = v.color * _Color;
                return OUT;
            }

            sampler2D _MainTex,_MaskTex;

            fixed4 frag(v2f IN) : SV_Target
            {
            	//float2 gridID = floor(IN.texcoord.xy*_TileCount);
            	float2 grids = frac(IN.texcoord.xy*_TileCount); 
            	float gridScale = lerp(0.1,5,_Threshold);
            	grids.x = 1-grids.x;
            	float2 edge = step(0.1,grids*gridScale);
            	//cell edges 
            	float2 edgetl = step(0.01,(grids.xy-0.98));
            	float2 edgebr = 1-step(0.12,(grids.xy*gridScale));
       			half cell = 1-edge.x*edge.y;
       			edgebr *= edge.x*edge.y;
       			half edgeC = saturate( (dot(float4(edgetl.xy,edgebr.xy),1))*(edge.x*edge.y) );
				
                half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd);
                half rawMask = tex2D(_MaskTex,IN.texcoord).r;

                float tempThres = (_Threshold-0.1)*1.4;
               	half mask = step(rawMask,tempThres);
               	half dabs = abs(rawMask-tempThres);
               	half mask2 = step(0.025,dabs);
               	half maskV = 1-saturate(dabs*mask2*5);
                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

             //   #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
              //  #endif
                float4 vfx = maskV*_Color;
                vfx.a = 1;
				fixed4 rlt = lerp(_BackGroundColor + edgeC.xxxx * mask * fixed4(0.5, 0.5, 0.5, 1),
					fixed4(color.xyz, _MainTexOpaque), 
					max(0, _Threshold) * mask);
					//max(0, (_Threshold - 0.5) * 2));
				rlt = lerp(rlt,vfx+rlt,maskV);

				return fixed4(rlt.rgb, color.a * mask);
            }
        ENDCG
        }
    }
}

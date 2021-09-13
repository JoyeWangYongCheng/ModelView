

Shader "TA_ren/ren_PopArrow" {
    Properties {
        _Color ("Color", Color) = (0.07843138,0.3921569,0.7843137,1)
        _ColorBG ("ColorBG", Color) = (0,0.04054837,0.1254902,1)
        _Emission ("Emission", Float ) = 1
      
        _GridDensity ("网格大小", Float ) = 16
        _ArrowAmount ("流动数量", Float ) = 2
        _Speed ("Speed", Float ) = 0.5
        _Offset("Offset",float)=1
        [MaterialToggle] _UseAlpha ("UseAlpha", Float ) = 1
       _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _MainTex ("MainTex", 2D) = "white" {}
        _MaskTex ("MaskTex", 2D) = "white" {}
     
       // _Emission ("Emission", Float ) = 1
    
       
        _refVal("模板测试",int)=12
      // _Alpha ("Alpha",float) = 1




       // _ColorInside ("ColorInside", Color) = (0.3945098,0.7843137,0.7772973,1)
       // _TimeScale ("TimeScale", Float ) = 1
        _Ring_Thickness ("圆圈宽度", Range(0, 1)) = 0.1
        _Opacity ("圆圈亮度", Range(0, 1)) = 1
       //  _CirColor ("圆圈颜色", Color) = (1,1,1,1)

         _TimeScale("圆圈速度",float)=1
       // _ColorOutside ("ColorOutside", Color) = (0.07843138,0.3921569,0.7803922,1)
       // _Emission ("Emission", Float ) = 1
      //  [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "Queue"="Transparent"
            "RenderType"="TransparentCutout"
        }
        Pass {
            Stencil
		{
			Ref [_refVal]
			Comp Always //比较成功条件 
			Pass Replace //条件成立 写入到Stencil
			Fail Keep   //条件不成立 保持Stencil
			ZFail Keep //Z测试失败 保持Stencil
		}
     
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
           // #pragma only_renderers d3d9 d3d11 glcore gles 
           // #pragma target 3.0
            uniform float4 _Color;
             uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _ArrowAmount;
            uniform float _Speed;
            uniform float _GridDensity;
            uniform float4 _ColorBG;
            uniform float _Emission;
            uniform fixed _UseAlpha;
           sampler2D   _MaskTex; float4 _MaskTex_ST;
            float  _Offset;
          float  _Cutoff;
          float  _Alpha;
          

         //  uniform float4 _ColorInside;
            uniform float _TimeScale;
            uniform float _Ring_Thickness;
            uniform float _Opacity;
             float TimeA;
          //  uniform float4 _ColorOutside;
           // uniform float _Emission;
        
          
            
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                 float2 texcoord1 : TEXCOORD1;
                 float2 texcoord2 : TEXCOORD2;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                 float2 uv2 : TEXCOORD2;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                 o.uv2 = v.texcoord2;
              
                o.pos = UnityObjectToClipPos( v.vertex);
           
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
//CirFlow
                // float4 MainTexMask = (tex2D(_MaskTex,TRANSFORM_TEX(i.uv1, _MaskTex)));
                float CirRadius = distance(i.uv0,float2(0.5,0.5));
               
                float Circle  = (1.0 - CirRadius);
               // return Circle;
              //  float3 emissive = (lerp(_ColorOutside.rgb,_ColorInside.rgb,smoothstep( 0.5, 1.0, Circle  ))*_Emission);
               // float3 finalColor = emissive;//*MainTexMask*_MaskColor;
            // float flowColor = saturate((saturateU*step(length((frac((i.uv0*_GridDensity))*2+-1.0)),0.75)*saturateU));
                //float4 TimeA = _Time;
                float CirRadA = (CirRadius*3.0);
                
               // return CirRadA;
                float CirRadAB = (CirRadA*CirRadA);
               float CirFlow =(//smoothstep( 0.5, 0.7, Circle)*
                floor((frac((float2(CirRadAB,CirRadAB)+(_Time*(-1.0)*_TimeScale)*float2(1,0))).r+_Ring_Thickness))
                *_Opacity);
                 float CirflowColor = saturate((CirFlow*step(length((frac((i.uv0*_GridDensity))*2+-1.0)),0.75)*CirFlow));

                //  float3 Ciremissive = (lerp(_ColorBG.rgb,_Color.rgb,CirflowColor));
                  // clip( ( lerp( _ColorBG, FinalflowColor, _UseAlpha ) - 0.5)*_Cutoff);
              //return CirflowColor;


               

                 
               
                float4 MainTexSample = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                 float4 MainTexMask = (tex2D(_MaskTex,TRANSFORM_TEX(i.uv1, _MaskTex)));
                
 // triangle flow           
                 float UVOffset=frac( i.uv2.r+_Offset);
                float2 _GridFloat = floor(i.uv2 * _GridDensity) / (_GridDensity-1 );
        // return  _GridFloat;
                float saturateU = (1.0 - frac(((_ArrowAmount*(_GridFloat.g-abs((_GridFloat.r-0.5))))+  (_Time*_Speed))));
                
                //return saturateU;
                float flowColor = saturate((saturateU*step(length((frac((i.uv2*_GridDensity))*2+-1.0)),0.75)*saturateU));
                float FinalflowColor=flowColor;
               // return FinalflowColor;
                clip( ( lerp( _Color.rgb, FinalflowColor, _UseAlpha ) - 0.5)*_Cutoff);

                float3 emissive = (lerp(_ColorBG.rgb,_Color.rgb,FinalflowColor)*_Emission);
               
                float3 finalColor = emissive*MainTexMask*_Color*MainTexSample*CirflowColor;
                 //return fixed4( finalColor,1);
               // float alphaVal =emissive.a*MainTexMask.a*MainTexSample.a*flowColor;
                return fixed4(emissive+finalColor,1);
            }
            ENDCG
        }
         
         
         
      
    }
FallBack "Transparent/VertexLit"
   
}

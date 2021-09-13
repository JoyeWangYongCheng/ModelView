// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "P5/Unlit/ParticlesDisSelf_Alpha" {
Properties {
        _TintColor("Tint Color",Color) = (1,1,1,1)
        _MainTex ("Base (RGB) Trans (A)", 2D) = "black" {}
        _AlphaTex ("Alpha (RGB)", 2D) = "white" {}
        _noiseTex ("Noise Tex", 2D) = "white" {}
        _HeatSpeed ("Heat speed",Vector) = (0,0,0,0)
        _HeatForce  ("Heat Force", range (0,0.2)) = 0

        _Emission ("Emission", Range(0,8)) = 1
}

SubShader {
        Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}        
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off 

        Pass {  
                CGPROGRAM
                        #pragma vertex vert
                        #pragma fragment frag
                        #pragma fragmentoption ARB_precision_hint_fastest        
                        #include "UnityCG.cginc"

                        struct appdata_t {
                                float4 vertex : POSITION;
                                float2 texcoord : TEXCOORD0;
                                float4 color : COLOR;
                        };

                        struct v2f {
                                float4 vertex : SV_POSITION;
                                float2 texcoord : TEXCOORD0;
                                float4 color : COLOR;
                        };

                        float4 _MainTex_ST;
                        sampler2D _MainTex;
                        sampler2D _AlphaTex;
                        sampler2D _noiseTex;
                        float4 _TintColor;
                  
                        half4 _HeatSpeed;
                    half _HeatForce;
                        half _Emission;

                        
                        v2f vert (appdata_t v)
                        {
                                v2f o;
                                o.vertex = UnityObjectToClipPos(v.vertex);
                                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                                o.color = v.color*_TintColor;

                                return o;
                        }
                        
                        fixed4 frag (v2f i) : SV_Target
                        {
                                float2 uv = i.texcoord;
                                half2 offsetColor1 = tex2D(_noiseTex, uv + _Time.xz * _HeatSpeed.x).rg;
                            half2 offsetColor2 = tex2D(_noiseTex, uv - _Time.yx * _HeatSpeed.y).rg;
                            
                                uv.x += ((offsetColor1.r + offsetColor2.r) - 1) * _HeatForce;
                                uv.y += ((offsetColor1.g + offsetColor2.g) - 1) * _HeatForce;
                                
                                
                                fixed4 mainCol = tex2D(_MainTex, uv);
                                fixed alphaCol = tex2D(_AlphaTex, uv).r;                        
                                
                                fixed4 finalCol = mainCol  * _Emission * i.color;
                                return float4(finalCol.rgb,finalCol.a*alphaCol);

                        }
                ENDCG
                }
        }
        FallBack "Mobile/Particles/Addtive"
}
Shader "P5/Unlit/UIFX01" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _FX ("FX", 2D) = "black" {}
        _Speed ("Speed", Range(0, 5)) = 1.307692
        _FxColor ("FxColor", Color) = (0.5,0.5,0.5,1)
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        LOD 100
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            uniform float4 _TimeEditor;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _FX; uniform float4 _FX_ST;
            uniform float _Speed;
            uniform float4 _FxColor;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos( v.vertex );
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
////// Lighting:
////// Emissive:
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float4 node_959 = _Time + _TimeEditor;
                float2 node_4168 = (((_MainTex_var.r*float2(1,0))+i.uv0)+(node_959.g*_Speed)*float2(0.1,0.1));
                float4 _FX_var = tex2D(_FX,TRANSFORM_TEX(node_4168, _FX));
                float3 emissive = (_MainTex_var.rgb+(_FX_var.rgb*_FxColor.rgb));
                float3 finalColor = emissive;
                return fixed4(finalColor,_MainTex_var.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}

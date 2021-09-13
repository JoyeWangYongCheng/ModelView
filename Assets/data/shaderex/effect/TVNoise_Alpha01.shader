// Shader created with Shader Forge v1.38 
// Shader Forge (c) Freya Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:1,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:0,bsrc:3,bdst:7,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:True,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:False,fgod:False,fgor:False,fgmd:0,fgcr:0.5,fgcg:0.5,fgcb:0.5,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:False,fnfb:False,fsmp:False;n:type:ShaderForge.SFN_Final,id:9361,x:33209,y:32712,varname:node_9361,prsc:2|emission-965-OUT,alpha-5628-A;n:type:ShaderForge.SFN_Add,id:1381,x:31918,y:32558,varname:node_1381,prsc:2|A-1161-OUT,B-4404-UVOUT;n:type:ShaderForge.SFN_TexCoord,id:4404,x:31918,y:32735,varname:node_4404,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_RemapRange,id:1161,x:31743,y:32899,varname:node_1161,prsc:2,frmn:0,frmx:1000,tomn:0,tomx:1|IN-2926-OUT;n:type:ShaderForge.SFN_Slider,id:2926,x:31630,y:33110,ptovrint:False,ptlb:Noise_Strength,ptin:_Noise_Strength,varname:node_2926,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0,max:1000;n:type:ShaderForge.SFN_RemapRange,id:6845,x:31932,y:32899,varname:node_6845,prsc:2,frmn:0,frmx:1,tomn:0,tomx:0.1|IN-1161-OUT;n:type:ShaderForge.SFN_Tex2d,id:8752,x:32172,y:32558,ptovrint:False,ptlb:NoiseTex,ptin:_NoiseTex,varname:node_8752,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,tex:b842f61d93e9ddc45a58ea4bf16fda47,ntxv:0,isnm:False|UVIN-1381-OUT;n:type:ShaderForge.SFN_Append,id:6663,x:32356,y:32575,varname:node_6663,prsc:2|A-8752-R,B-8752-R;n:type:ShaderForge.SFN_Multiply,id:2795,x:32424,y:32755,varname:node_2795,prsc:2|A-6845-OUT,B-6663-OUT;n:type:ShaderForge.SFN_Add,id:1127,x:32603,y:32668,varname:node_1127,prsc:2|A-2795-OUT,B-4404-UVOUT;n:type:ShaderForge.SFN_Tex2d,id:5628,x:32786,y:32668,ptovrint:False,ptlb:MainTex,ptin:_MainTex,varname:node_5628,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-1127-OUT;n:type:ShaderForge.SFN_Multiply,id:965,x:33044,y:32644,varname:node_965,prsc:2|A-5628-RGB,B-7497-OUT;n:type:ShaderForge.SFN_TexCoord,id:8426,x:32216,y:33014,varname:node_8426,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Multiply,id:4627,x:32424,y:33126,varname:node_4627,prsc:2|A-8426-V,B-2926-OUT;n:type:ShaderForge.SFN_Sin,id:9507,x:32625,y:33126,varname:node_9507,prsc:2|IN-4627-OUT;n:type:ShaderForge.SFN_Clamp01,id:1790,x:32797,y:33126,varname:node_1790,prsc:2|IN-9507-OUT;n:type:ShaderForge.SFN_RemapRange,id:3237,x:32966,y:33066,varname:node_3237,prsc:2,frmn:0,frmx:1,tomn:0.6,tomx:1|IN-1790-OUT;n:type:ShaderForge.SFN_Add,id:7497,x:33126,y:33170,varname:node_7497,prsc:2|A-3237-OUT,B-1163-OUT;n:type:ShaderForge.SFN_Vector1,id:1163,x:32948,y:32952,varname:node_1163,prsc:2,v1:0.2;proporder:5628-8752-2926;pass:END;sub:END;*/

Shader "MadShader/TVNoise_Alpha01" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {}
        _Noise_Strength ("Noise_Strength", Range(0, 1000)) = 0
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _Angle("Angle",Range(-3.14,3.14))=0
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
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
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            //#pragma only_renderers d3d9 d3d11 glcore gles 
            //#pragma target 3.0
            uniform float _Noise_Strength;
            uniform sampler2D _NoiseTex; uniform float4 _NoiseTex_ST;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            fixed _Angle;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                UNITY_FOG_COORDS(1)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
////// Lighting:
////// Emissive:
                float node_1161 = (_Noise_Strength*0.001+0.0);
                float2 node_1381 = (node_1161+i.uv0);
                float2 poivt = float2(0.5,0.5);
                float2x2 rotationMatrix = float2x2(cos(_Angle),-sin(_Angle),sin(_Angle),cos(_Angle));
                float2 uv = i.uv0;
                uv-=poivt;
                uv = mul(uv,rotationMatrix);
                uv+=poivt;
                // return tex2D(_MainTex,uv);

                float4 _NoiseTex_var = tex2D(_NoiseTex,TRANSFORM_TEX(uv, _NoiseTex));
                float2 node_1127 = (((node_1161*0.1+0.0)*float2(_NoiseTex_var.r,_NoiseTex_var.r))+i.uv0);
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(node_1127, _MainTex));
                float3 emissive = (_MainTex_var.rgb*((saturate(sin((i.uv0.g*_Noise_Strength)))*0.4+0.6)+0.2));
                float3 finalColor = emissive;
                fixed4 finalRGBA = fixed4(finalColor,_MainTex_var.a);
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
    CustomEditor "ShaderForgeMaterialInspector"
}

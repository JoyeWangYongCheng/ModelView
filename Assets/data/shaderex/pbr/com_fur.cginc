
#ifndef _LAYEREDFUR_INC_
#define _LAYEREDFUR_INC_
    #include "UnityCG.cginc"
    #include "Lighting.cginc"
    #include "AutoLight.cginc"
    #include "UnityStandardBRDF.cginc"
    #include "UnityStandardUtils.cginc"
    #include "com.cginc"
    
    sampler2D _FlowMap;
    sampler2D _MaskTex;
    float4 _MaskTex_ST,_MainTex_ST;
    float4 _MaskTex_TexelSize;
    float4 _FurRotTex_ST;

    half _Cutoff;
    half _CutoffEnd;
    half _FurLightIntensity;

    half _MinOcclusion,_MaxOcclusion;

    float3 _G = float3(0,-2.0,0); 
    
    half3 _FurColor;
    half _FurLength,_EdgeFade,_SpecularOffset;
    float _Offset;

    half _FurMoveStrength,_Roughness;
	half4 _SHColor;
	half _SHIntensity;

    #define LAYER_THICKNESS _FurLength*0.111111
    
 //   #define LAYER 0
    
    inline float FabricD (float NdotH, float roughness)
    {
         return roughness * pow(1 - NdotH, 2) + 0.057;
    }

    struct VertexInput
    {
        float4 vcolor : COLOR;
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float4 tangent : TANGENT;
     //   float4 color : TEXCOORD2;
    };

    
    struct VertexOutput
    {
        float4 pos : SV_POSITION;
        float4 uv : TEXCOORD0;
        float3 normal : TEXCOORD1;
        float3 posWS : TEXCOORD2;
        float4 ambient : TEXCOORD3;
        float3 tangent : TEXCOORD4;
        float3 view  : TEXCOORD5;
  //      float4 dc : TEXCOORD6;
  //      float4 color : TEXCOORD7;

    };
    
    VertexOutput furVertex(VertexInput v)
    {
        VertexOutput o;
        
        float3 oriPosWS = mul(unity_ObjectToWorld,float4(v.vertex.xyz,1));
        
        float3 normalWS = UnityObjectToWorldNormal(v.normal);
        
        /*     
        float3 T = v.tangent.xyz;
        //tangentWorld = normalize(tangentWorld);
        float3 B =normalize( cross(v.normal,T)*v.tangent.w);

        float3x3 TBN = float3x3(T.x,B.x,v.normal.x,
                                T.y,B.y,v.normal.y,
                                T.z,B.z,v.normal.z); 

        float3 furDir =  mul(TBN,v.color);
        */
        float3 furDir =  v.normal;
        o.tangent = mul(unity_ObjectToWorld,float4(v.tangent.xyz,0) );
        float3 GOS = mul(unity_WorldToObject,half4(0,-0.001*LAYER,0,0)).xyz;
        float k = pow(LAYER*0.1,2);
        float3 posOS = v.vertex+(furDir)*LAYER_THICKNESS*LAYER;
        o.view = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,float4(posOS,1)));
        posOS = posOS + k*GOS;
        

        o.pos = UnityObjectToClipPos(posOS); 
        o.normal =normalWS;
         
        o.posWS = mul(unity_ObjectToWorld,float4(posOS,1));
        o.uv.xy = (v.uv);
       // o.tangent =  mul(TBN,v.color*2-1);//;normalize( mul(unity_ObjectToWorld,  v.tangent));

        o.uv.zw = TRANSFORM_TEX(v.uv1,_MaskTex);
        o.ambient = 0;
        o.ambient.rgb = _ShadeSHPerVertex(o.normal,o.ambient.rgb);

        return o;
    }


   half4 furFragShadow(VertexOutput i) : SV_TARGET
    {
        float3 N = normalize(i.normal);
		half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
        float4 shadowPos = float4(i.posWS.xyz,1);
        float4 ndcpos = mul(_HQCharCameraVP,shadowPos);
        ndcpos.xyz/=ndcpos.w;
        float3 uvpos = ndcpos*0.5+0.5;  
        float ndml = dot(N,lightDir.xyz);
        
        float bias = 0.005*sqrt(1-ndml*ndml)/ndml;        
        half atten  = 1;             
                   
        half atten1 = PCFForNoTrans(uvpos.xy,ndcpos.z,_Bias);    
        half atten2 =  ( PCF(uvpos.xy,ndcpos.z,_Bias));
        atten = min(atten1,atten2);  
		
        float4 furColor = tex2D(_MainTex,i.uv.xy);
      //  return furColor;
        clip(furColor.a-0.2);     

        
    
        float3 T = normalize(i.tangent);

        float3 view = normalize(i.view);
        float3 H =  normalize(view+lightDir.xyz);
        half tdh = (dot(T,H));
        
        half layerWeight = 0.12*LAYER;
        
        half ndl = saturate(dot(N,lightDir.xyz));
		float fixAtten = min(ndl,atten);
        half ndv = saturate(dot(N,view));
		
        half ldh = saturate(dot(lightDir.xyz,H));
        half dirAtten = smoothstep(-1.0,0.0,tdh);

        half kjyspec = dirAtten*pow(sqrt(1-tdh*tdh),1024*_Roughness)*0.1;
        kjyspec =pow(1-ndv,5);
        

        float4 texColor = tex2D(_MaskTex,i.uv.zw);
     //   return texColor;
        texColor.a = step(lerp(_Cutoff, _CutoffEnd, layerWeight), texColor.r);
        fixed occ = lerp(_MinOcclusion,_MaxOcclusion,layerWeight+texColor.r);
        float diffuseTerm = DisneyDiffuse(ndv,ndl,ldh,_Roughness)*ndl*_FurLightIntensity;

        kjyspec*=(texColor.a*occ);

        float3 shgi = ShadeSHPerPixel(N,i.ambient,i.posWS);
        half3 rlt = furColor.rgb*(diffuseTerm+shgi) + _FurColor*kjyspec;
		return 0;
		return half4(rlt.rgb*(occ)*(fixAtten*0.5+0.6),(1-fixAtten)*furColor.a);
        //return half4(rlt.rgb*(occ),texColor.a*furColor.a*(1-layerWeight));
    }


    half4 furFrag(VertexOutput i) : SV_TARGET
    {

        float3 N = normalize(i.normal);
		half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
        float4 shadowPos = float4(i.posWS.xyz,1);
        float4 ndcpos = mul(_HQCharCameraVP,shadowPos);
        ndcpos.xyz/=ndcpos.w;
        float3 uvpos = ndcpos*0.5+0.5;  
        float ndml = dot(N,lightDir.xyz);
        
        float bias = 0.005*sqrt(1-ndml*ndml)/ndml;        
        half atten  = 1;             
                   
        half atten1 = PCFForNoTrans(uvpos.xy,ndcpos.z,_Bias);    
        half atten2 =  ( PCF(uvpos.xy,ndcpos.z,_Bias));
        atten = min(atten1,atten2);

        
        float4 furColor = tex2D(_MainTex,i.uv.xy);
      //  return furColor;
        clip(furColor.a-0.2);     

        float3 T = normalize(i.tangent);

        float3 view = normalize(i.view);
        float3 H =  normalize(view+lightDir.xyz);
        half tdh = (dot(T,H));
        
        half layerWeight = 0.12*LAYER;
        
        half ndl = saturate(dot(N,lightDir.xyz));

        half ndv = saturate(dot(N,view));

        half ldh = saturate(dot(lightDir.xyz,H));
        half dirAtten = smoothstep(-1.0,0.0,tdh);

        half kjyspec = dirAtten*pow(sqrt(1-tdh*tdh),1024*_Roughness)*0.1;
        kjyspec =pow(1-ndv,5);
        

        float4 texColor = tex2D(_MaskTex,i.uv.zw);
     //   return texColor;
        texColor.a = step(lerp(_Cutoff, _CutoffEnd, layerWeight), texColor.r);
        fixed occ = lerp(_MinOcclusion,_MaxOcclusion,layerWeight+texColor.r);
        float diffuseTerm = DisneyDiffuse(ndv,ndl,ldh,_Roughness)*ndl*_FurLightIntensity;

        kjyspec*=(texColor.a*occ);

        float3 shgi = (ShadeSHPerPixel(N,i.ambient,i.posWS)*_SHColor.rgb+_SHIntensity)*(1-(1-atten)*0.5);
        half3 rlt = furColor.rgb*(diffuseTerm+shgi) + _FurColor*kjyspec;

		//float3 lmdAtten = furColor.rgb*(diffuseTerm+shgi*ndl);
		//return float4(shgi*(1-(1-atten)*0.5),1);
		//return half4(lmdAtten,texColor.a*furColor.a*(1-layerWeight) );
		return half4( rlt.rgb*(occ) ,texColor.a*furColor.a*(1-layerWeight));
    }

    struct a2v
    {
        float4 vcolor : COLOR;
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float4 tangent : TANGENT;
     //   float4 color : TEXCOORD2;
    };   
    struct v2f{
        float4 pos : SV_POSITION;
        float4 uv : TEXCOORD0;
        float3 normal : TEXCOORD1;
        float3 posWS : TEXCOORD2;
        float4 ambient : TEXCOORD3;
        float3 tangent : TEXCOORD4;
        float3 view  : TEXCOORD5;
        SHADOW_COORDS(6)
    };


	VertexOutput bloomVertex(VertexInput v)
	{
		VertexOutput o;
		o.pos = UnityObjectToClipPos(v.vertex);
		return o;
	}



    fixed4 bloomFrag(v2f i):SV_Target{

        return 0;

    }

    
   
    #endif

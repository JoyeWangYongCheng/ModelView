Shader "LMD/Scene/Diffuse_BuildingLights"
{
	Properties
	{
		_LightColor("Light Color", Color) = (1,1,1)
		_LightWidth("Light Width",Range(0,0.5)) = 0.3
		_LightHeight("Light Height",Range(0,0.5)) = 0.3
		_LightIntensity("Max Light Per Floor",int) = 10
		_FloorCount("Floor Count",int) = 10
		_MainTex ("Texture", 2D) = "black" {}

		// _LightPower("Light Power",Range(1,2)) = 1 
		_FloorPara("Building Light Intensity",Range(0,1)) = 0.3
		_FloorLightIntensity("Floor Light Intensity",Range(0,1)) = 0.3
		_FogColor("Fog Color", Color) = (1,1,1,1)
		_FogFactor("Factor", Range(0, 0.05)) = 0
		_LightPowerRandom("LightPowerRandom",Range(0,1)) = 1
		_LightBorder("LightBorder",vector)=(0,0,0,0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            #pragma multi_compile_fwdbase
			#pragma multi_compile __ _OUTPUT_BLOOM_DATA

			fixed _LightPowerRandom;

			float rectangle(float2 samplePos, float2 halfSize)
			{	
				//samplePos+=0.5;
				fixed xx = step(abs(samplePos.x-0.5),halfSize.x);
				fixed yy = step(abs(samplePos.y-0.5),halfSize.y);
				return xx*yy;
				// samplePos-=0.5;
				// float2 componmentwiseEdgeDistance = abs(samplePos)-halfSize;
				// float od = length(max(componmentwiseEdgeDistance,0));
				// float id = min(max(componmentwiseEdgeDistance.x,componmentwiseEdgeDistance.y),0);
				// return  step(od+id,0.25);
			}

			fixed noise(float t) 
			{
				return frac(sin(t));	
			}

			fixed noise( float2 t)
			{
				return frac(sin( dot(t.xy,half2(12.9898,78.233)))*43758.5453123);
			}

			fixed pattern(float2 st, float2 v,half t)
			{
				half2 p = floor(st+v);

				return step(t, noise(float2(100.0,100.0)+p*0.00001) + noise(p.x)*0.5);
			}

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
				float2 uv2:TEXCOORD2;
                float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                UNITY_SHADOW_COORDS(3)
                float3 normal : TEXCOORD4;

                float2 ambientOrLightmapUV : TEXCOORD5;
				float fog:TEXCOORD1;
                float2 uv2:TEXCOORD6;

			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _LightSize,_FloorPara,_FloorLightIntensity;
			float _LightIntensity,_FloorCount;
			float3 _LightColor;
			float _LightWidth,_LightHeight,_LightPower;
			float4 _FogColor;
			float _FogFactor;
            uniform float st2BlackFactor;
			float2 _LightBorder;

		half SimulateFog(half4 pos)
		{
			#if defined(UNITY_REVERSED_Z)
				#if UNITY_REVERSED_Z == 1
						half z = max(((1.0 - (pos.z) / _ProjectionParams.y)*_ProjectionParams.z), 0);
				#else
						half z = max(-(pos.z), 0);
				#endif
			#else
						half z = pos.z;
			#endif

			half fogFactor = exp2(-_FogFactor * z);
			fogFactor = clamp(fogFactor, 0.0, 1.0);
			return fogFactor;
		}			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                // o.ambientOrLightmapUV = 0;
                // #ifdef LIGHTMAP_ON
                //     o.ambientOrLightmapUV.rgb = v.uv1.xy*unity_LightmapST.xy + 
                //                                 unity_LightmapST.zw;

                // #elif UNITY_SHOULD_SAMPLE_SH
                //     o.ambientOrLightmapUV.rgb = ShadeSHPerVertex(o.normal,o.ambientOrLightmapUV.rgb);
                // #endif
o.ambientOrLightmapUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

                UNITY_TRANSFER_SHADOW(o,o.worldPos);
                o.fog = SimulateFog(o.pos);
				o.uv2 = v.uv2;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				#ifdef _OUTPUT_BLOOM_DATA
				return 0;
				#endif
                half3 N = normalize(i.normal);
     
				float rcpFloorLight = 1.0/_LightIntensity;
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv.xy);
//  return tex2D(_MainTex,i.uv2);
				half ff = step(_LightBorder.x,i.uv2.x);
				ff *= step(i.uv2.x,_LightBorder.y);
				//return ff;		
				// apply fog
				half2 grid = int2(_LightIntensity,_FloorCount);
				half2 uvs = i.uv.zw*grid;

				// return fixed4(uvs.x+_LightBorder.x,uvs.y+_LightBorder.y,0,1);
				half2 uvi = floor(uvs);
				
				// uvi.x+= _LightBorder.x;
				half2 uv = frac(uvs);




				float3 objWSXZ = float3( unity_ObjectToWorld._m03,unity_ObjectToWorld._m13,unity_ObjectToWorld._m23);
				//return objWSXZ.x/10.0;
				half2 st = grid*i.uv.zw+objWSXZ.xz;
				//return uv;

				float dis = rectangle(uv,float2(_LightWidth,_LightHeight));
			// return dis;
				fixed cellnoise = lerp(1,noise(uvi),_LightPowerRandom);

				fixed yn = step(_FloorPara,noise(uvi.y+dot(half3(1,1,1),objWSXZ)));
				fixed p =  pattern(st,uvi.y*uvi.y,_FloorLightIntensity);

                // UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                // fixed ndl = saturate(dot(N,_WorldSpaceLightPos0.xyz));
                
                // fixed3 c = 0;
                // half3 giDiffuse = 0;//ShadeSHPerPixel(N,i.ambientOrLightmapUV,i.worldPos);
                
                //fixed3 lightTex = DecodeLightmap( UNITY_SAMPLE_TEX2D( unity_Lightmap, i.ambientOrLightmapUV ));
// return fixed4(lightTex,1);
                float3 light =float3(dis.xxx)*yn*p*ff*_LightColor.xyz*cellnoise;
                // c =   _LightColor0*ndl*atten+giDiffuse;
               
				half3 finalColor = light.xyz+col.rgb;//lightTex;
				
                return half4(lerp(_FogColor.rgb,finalColor,i.fog)* (1 - st2BlackFactor),1); 
			//	return fixed4(+c,1);
				
			}
			ENDCG
		}
	}
}

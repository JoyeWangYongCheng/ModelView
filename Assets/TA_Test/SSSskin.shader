Shader "TA_Test/SSSskin"
{
	Properties
	{
		_Color ("Main Color",Color)=(1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_BumpMap("Normal Tex",2D) = "bump" {}
		
		_MatCapDiffuse ("MatCap Diffuse", 2D) = "white" {}
		_DiffuseValue("Diffuse Value",Range(0,5)) = 1
		_MatCapSpec("MatCap Spec",2D) = "white"{}
		_SpecValue("Spec Value",Range(0,2)) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
 
		Pass
		{
			Tags {"LightMode"="Always"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

 			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 TtoV0:TEXCOORD1;
				float3 TtoV1:TEXCOORD2;
			};

            fixed4 _Color;
            sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D _MatCapDiffuse;
			fixed _DiffuseValue;
			sampler2D _MatCapSpec;
			fixed _SpecValue;

			// sampler2D _GlobalMatcap;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				// //将法线从模型空间转换到视觉空间，以便映射Matcap采样贴图
                // o.NtoV.x = mul(UNITY_MATRIX_IT_MV[0],v.normal);
				// o.NtoV.y = mul(UNITY_MATRIX_IT_MV[1],v.normal);
                o.uv = v.uv;
                
				TANGENT_SPACE_ROTATION;
				o.TtoV0 = normalize(mul(rotation,UNITY_MATRIX_IT_MV[0]).xyz);
				o.TtoV1 = normalize(mul(rotation,UNITY_MATRIX_IT_MV[1]).xyz);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 mainTex = tex2D(_MainTex,i.uv);
				float3 normal = UnpackNormal(tex2D(_BumpMap,i.uv));
				normal.z = sqrt(1.0-saturate(dot(normal.xy,normal.xy)));
				normal = normalize(normal);

				half2 vn;
				vn.x = dot(i.TtoV0,normal);
				vn.y = dot(i.TtoV1,normal);
               
				fixed4 matCapDiffuse = tex2D(_MatCapDiffuse,vn)*_DiffuseValue;
				fixed4 matCapSpec = tex2D(_MatCapSpec,vn)*_SpecValue;
				fixed4 finalColor = matCapDiffuse*mainTex*_Color+matCapSpec;
				return finalColor;
			}
			ENDCG
		}
	}
}

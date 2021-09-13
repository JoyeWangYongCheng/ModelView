Shader "streetball2/MeshEmission"
{
	Properties
	{
		[HDR]_Color("Color",Color) = (1,1,1,1)
		_FresnelPow("FresnelPow",Float) = 1
		_Intensity("Intensity",Float) = 1
		_Opacity("Opacity", Range(0,1)) = 0.5
		_Size("Size",Float) = 0.01
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
		ZWrite Off
		//Blend SrcAlpha OneMinusSrcAlpha

		LOD 100

		Stencil
		{
		    Ref 253
			Comp Greater
			Pass Replace
			Fail Keep
			ZFail Keep
		}

		Pass
		{
			Name "OutEmission"
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			//#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 normalWS : TEXCOORD1;
				float3 vertexWS : TEXCOORD2;
				float4 vertex : SV_POSITION;
			};

			half4 _Color;
			half _Intensity;
			half _FresnelPow;
			half _Opacity;
			half _Size;
			
			v2f vert (appdata v)
			{
				v2f o;
				v.vertex.xyz += _Size * v.normal;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertexWS = UnityObjectToWorldDir(v.vertex);
				o.normalWS = UnityObjectToWorldNormal(v.normal);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = _Color * 1;
				half3 viewDir = normalize(i.vertexWS - _WorldSpaceCameraPos.xyz);
				half NoV = saturate(dot(i.normalWS,viewDir));
				NoV = _Intensity*pow(NoV,_FresnelPow);
				col.a = NoV * _Opacity;
				return col;
			}
			ENDCG
		}
	}
}

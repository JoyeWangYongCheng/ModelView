
Shader "streetball2/model_battle_grey" {
	Properties{
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex("Albedo Tex", 2D) = "white" {}
		_MaskNrmMap("MaskNrmMap", 2D) = "black" {}
		_BumpValue("Normal Value", Range(0,10)) = 1

			// _Weights  x控制lightProbes  y控制皮肤范围  z控制皮肤边缘范围 w控制皮肤边缘颜色强度  
			_Weights("Skin Weights",vector) = (0.1,0.2,0.3,0.5)
			// _SpecularScale  x,y 控制皮肤高光   衣服高光参数写死，贴图来控制。  z 控制皮肤强度  w 控制皮肤边缘强度
			_SpecularScale("Specular Scale",vector) = (30,0.08,1,1)
			// _SkinBaseTint
			// _SkinRimSharpness ("SkinRim Sharpness",vector) = (1,1,1,1)
			_SkinRimColor("皮肤颜色",Color) = (0.976,0.67,0.67,1)
			// _SkinRimColorOffset ("SkinRim Color0Offset",Range(-1,1)) = 0
			_SkinRimColor1("皮肤边缘颜色",Color) = (0.627,0.38,0.38,1)
			// _SkinRimColor1Offset ("SkinRim Color1Offset",Range(-1,1)) = 0
			_Light("灯光方向",vector) = (-0.6,1,-1.75,0.2)
			[Enum(white,0, yellow,1, black,2,brown,3)] _SkinPreset("SkinPreset", Int) = 0
		_TattooTex("Tatto Color", 2D) = "white" {}
		_TattooToggle("Tattoo Toggle", Range(0, 1)) = 0
	}

		Subshader{
			Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }

			Pass {
				Tags{"LightMode" = "ForwardBase"}

				CGPROGRAM

					struct ShaderParams
					{
			//皮肤颜色与偏移
			float4 skinRimColorAndOffset;
			float4 skinRimColorAndOffset1;
			//ohter params 
			float4 skinScales;

		};




		#define SKIN_RIM skinRimColorAndOffset.xyz
		#define SKIN_RIM_OFFSET skinRimColorAndOffset.w

		#define SKIN_RIM_1 skinRimColorAndOffset1.xyz
		#define SKIN_RIM_OFFSET_1 skinRimColorAndOffset1.w


		// #define SKIN_SCALE_0 skinScales.x
		// #define SKIN_SCALE_1 skinScales.y
		// #define SKIN_SHINEESS skinScales.z
		// #define SKIN_SHINEESS_SCALE skinScales.w


		//init params here

		#define CLOTHES_SHINEESS 114
		#define CLOTHES_SPEC_SCALE 1.2
		// #pragma multi_compile _SKINPRESET _SKINPRESET_WHITE _SKINPRESET_YELLOW _SKINPRESET_BLACK _SKINPRESET_BROWN

		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		struct v2f {
			float4 pos : SV_POSITION;
			float4	uv : TEXCOORD0;
			float3 SHLighting:TEXCOORD1;

			// float4  T2W0 :TEXCOORD2;
			// float4  T2W1 :TEXCOORD3;
			// float4  T2W2 :TEXCOORD4;
			float3 tangent:TEXCOORD4;
			float3 binormal:TEXCOORD6;
			float3  worldPos : TEXCOORD2;
			float3  worldNrm : TEXCOORD3;
			float3 sh : TEXCOORD5;
		};

		uniform float4 _MaskNrmMap_ST;
		uniform float4 _MainTex_ST;
		uniform fixed4 _Color;
		uniform sampler2D _MaskNrmMap;
		// ,_MaskTex;
		uniform sampler2D _MatCapDiffuse;
		uniform sampler2D _MainTex;
		uniform sampler2D _MatCapSpec;
		uniform sampler2D _SpecTex;
		uniform fixed _BumpValue;
		uniform fixed _DiffuseValue;
		uniform fixed _SpecValue;
		uniform fixed _SpecTexValue;
		// fixed _R;
		// float _SkinRimColor1Offset;
		// float4 _SkinRimSharpness;

		fixed3 _SkinRimColor,_SkinRimColor1;
		half4 _Light;
		fixed4 _Weights;
		float4 _SpecularScale;
		uniform sampler2D _TattooTex;
		uniform fixed _TattooToggle;

		v2f vert(appdata_tan v)
		{
			v2f o;

			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
			o.uv.zw = TRANSFORM_TEX(v.texcoord,_MaskNrmMap);
			float3 worldNormal = UnityObjectToWorldNormal(v.normal);
			o.SHLighting = ShadeSH9(float4(worldNormal,1));
			float3 worldPos = mul(UNITY_MATRIX_M,v.vertex);
			o.tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
			float vv = 1 - 2 * (step(1.5, length(v.tangent.xyz)));
			o.binormal = cross(o.tangent, worldNormal) * vv * v.tangent.w;

			// float3 worldTangent = UnityObjectToWorldDir(v.tangent);
			// float3 worldBiTan = cross(worldNormal,worldTangent)*v.tangent.w;

			// o.T2W0 = float4(worldTangent.x,worldBiTan.x,worldNormal.x,worldPos.x);
			// o.T2W1 = float4(worldTangent.y,worldBiTan.y,worldNormal.y,worldPos.y);
			// o.T2W2 = float4(worldTangent.z,worldBiTan.z,worldNormal.z,worldPos.z);
			o.worldPos = worldPos;
			o.worldNrm = worldNormal;
			o.sh = ShadeSH9(float4(worldNormal,0));

			return o;
		}



		fixed lum(fixed3 col)
		{
			return saturate(col.r * 0.2 + col.g * 0.7 + col.b * 0.1);
		}


		float3 caluSkinColor(float3 halfVec,float3 view, float3 normal,float shLum)
		{

			float rimFactor = 1.0 - saturate(dot(view,normal));
			float skinRim = _Weights.y;
			float skinRim1 = pow(saturate(rimFactor + _Weights.w),2)*_Weights.z*shLum;
			fixed3 skinColor = 0;
			skinColor.rgb += (skinRim*_SkinRimColor + skinRim1 * _SkinRimColor1);


			// half3 halfVec = normalize(view+_Light.xyz);
			float spec = pow(saturate(dot(halfVec,normal)),_SpecularScale.x)*_SpecularScale.y;
			skinColor += spec;

			return skinColor;
		}
		float3 blinnSpecColor(float3 halfVec, float3 normal)
		{
			float spec = pow(saturate(dot(halfVec,normal)),CLOTHES_SHINEESS)*CLOTHES_SPEC_SCALE;
			return spec;
		}

		float4 frag(v2f i) : COLOR
		{
			// #if _SKINPRESET_WHITE
			// ShaderParams skinParams;
			// skinParams.skinRimColorAndOffset = float4(0.972,0.556,0.556,1);
			// skinParams.skinRimColorAndOffset1 = float4(0.913,0.913,0.913,-0.218);
			// skinParams.skinScales = float4(0.2,-0.25,7.16,0.06);
			// #endif


			float3 lightDir = normalize(_Light).xyz;
			fixed4 nrmAndMasks = tex2D(_MaskNrmMap,i.uv.xy);
			// fixed4 masks = tex2D(_MaskTex,i.uv);
			// return nrmAndMasks.a;
			// return masks.a;

			// float3x3 TBN = float3x3(i.T2W0.xyz,
			// 						i.T2W1.xyz,
			// 						i.T2W2.xyz);
			// float3 normal = UnpackNormal(tex2D(_MaskNrmMap,i.uv.zw));
			// normal = normalize( mul(TBN,normal) );
			// float3 worldPos = float3(i.T2W0.w,i.T2W1.w,i.T2W2.w);

			half3 tangent = normalize(i.tangent);
			half3 binormal = normalize(i.binormal);
			nrmAndMasks.xy = nrmAndMasks.xy * 2 - 1;
			half3 normalOffset = nrmAndMasks.x * tangent + nrmAndMasks.y * binormal;
			half3 normal = normalize(i.worldNrm + normalOffset);

			// return float4(normal,1);
			float3 worldPos = i.worldPos;

			float ndl = saturate(dot(normal,lightDir));


			fixed3 SHLighting = i.sh;

			float shLum = 1.0 - lum(SHLighting);
			float3 view = normalize(_WorldSpaceCameraPos.xyz - worldPos);
			half3 halfVec = normalize(view + lightDir.xyz);

			//read baked texture
			fixed4 c = tex2D(_MainTex, i.uv.xy);
			fixed4 tattoo = tex2D(_TattooTex, i.uv.xy * 4);
			c.rgb = lerp(c.rgb, tattoo.rgb, tattoo.a * _TattooToggle);
			// return c;
			c.rgb += SHLighting * _Weights.x;

			fixed3 clothColor = blinnSpecColor(halfVec,normal)*nrmAndMasks.a*(1 - nrmAndMasks.b);
			c.xyz += clothColor;
			fixed3 skinColor = caluSkinColor(halfVec,view,normal,shLum)*nrmAndMasks.b*ndl;
			c.xyz += skinColor;
			// return c*(1-nrmAndMasks.b)*_Light.w+c*nrmAndMasks.b;


			c = pow(c,1.2);
			c = lerp(c, c*(nrmAndMasks.b), _Light.w*-1);
			float grey = dot(c.rgb, fixed3(0.22, 0.707, 0.071));
			fixed4 final = half4(grey, grey, grey,c.a) * _Color;

			return final;
		}

	ENDCG
}
		}

			// CustomEditor "st2_player_battle_newGUI"
}
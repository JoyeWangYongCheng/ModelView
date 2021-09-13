Shader "DynamicShadow/ShadowReceiver"
{
	Properties
	{
		_ShadowColor ("Shadow Color", Color) = (0,0,0,1)
	}
	SubShader
	{
		Tags { "IGNOREPROJECTOR"="true" "RenderType"="Transparent" "Queue"="Transparent"}
		LOD 100
		Cull Back
		Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			
		}
	}
}

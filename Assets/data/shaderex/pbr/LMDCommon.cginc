#ifndef LMDCOMMON_INCLUDED
#define LMDCOMMON_INCLUDED

#ifdef NUMBER_HIGHT_ACCURACY

#define ColorNumber4 float4
#define ColorNumber3 float3
#define ColorNumber2 float2
#define ColorNumber  float
#define VectorNumber4 float4
#define VectorNumber3 float3
#define VectorNumber2 float2
#define VectorNumber  float

#else

#define ColorNumber4 fixed4
#define ColorNumber3 fixed3
#define ColorNumber2 fixed2
#define ColorNumber  fixed
#define VectorNumber4 float4
#define VectorNumber3 float3
#define VectorNumber2 float2
#define VectorNumber  float

#endif

#endif // UNITY_STANDARD_INPUT_INCLUDED
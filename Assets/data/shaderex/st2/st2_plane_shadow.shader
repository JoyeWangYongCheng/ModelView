//===========================================================
// StreetBall2-Plane Shadow-Shader
// Author: Xia Liqiang
// Version : 1.0.0
// Date : 2018.3.16
//===========================================================
Shader "streetball2/plane_shadow" {
   Properties {
      _ShadowColor ("Shadow's Color", Color) = (0,0,0,1)
	  _LightDir ("Light Direction", Vector) = (0.2,1,-0.4,0)
	  _Y ("Y", Float) = 0
   }
   SubShader {
	Pass {   
         Tags { "Queue"="Transparent" "LightMode" = "ForwardBase" } 
		 Cull Back 
      }
   }
}

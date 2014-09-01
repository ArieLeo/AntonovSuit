Shader "Hidden/Antonov Suit/Irradiance/Sphere 64" 
{
	Properties 
	{
		_DiffCubeIBL ("Diffuse Cube", Cube) = "black" {}
	}
	SubShader 
	{
		Pass 
		{
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 

			#ifdef SHADER_API_OPENGL	
				#pragma glsl
			#endif
			
			#pragma target 3.0
			
			#define ANTONOV_SPHERE
			#define ANTONOV_64_SAMPLES
			#define ANTONOV_IMPORTANCE_DIFFUSE
			
			#include "UnityCG.cginc"
			#include "../../AntonovSuitInput.cginc"
			#include "../../AntonovSuitLib.cginc"
			#include "../../AntonovSuitBRDF.cginc"
		
			#include "AntonovSuitImportanceFrag.cginc"
			
			ENDCG
		}
	}
}

Shader "Hidden/Antonov Suit/Irradiance/Hemisphere 256" 
{
	Properties 
	{
		_diffuseSize("Diffuse Cube Size", float) = 256
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
			
			#define ANTONOV_HEMISPHERE
			#define ANTONOV_256_SAMPLES
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

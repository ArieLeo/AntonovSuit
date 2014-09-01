Shader "Hidden/Antonov Suit/Radiance/GGX 128" 
{
	Properties 
	{
		_Shininess("Roughness", Range (0.001,1)) = 1.0
		_specularSize("Specular Cube Size", float) = 256
		_SpecCubeIBL ("Specular Cube", Cube) = "black" {}
	}
	SubShader 
	{
		Pass 
		{
			Tags 
			{ 
				"Queue"="Background"
				"RenderType"="Background"
			}
			
			Cull Off 
			ZWrite Off 
			Fog { Mode Off }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 

			#ifdef SHADER_API_OPENGL	
				#pragma glsl
			#endif
			
			#pragma target 3.0

			#define ANTONOV_GGX
			#define ANTONOV_128_SAMPLES
			#define ANTONOV_IMPORTANCE_SPECULAR

			#include "UnityCG.cginc"
			#include "../../AntonovSuitInput.cginc"
			#include "../../AntonovSuitLib.cginc"
			#include "../../AntonovSuitBRDF.cginc"
			
			#include "AntonovSuitImportanceFrag.cginc"
			
			ENDCG
		}
	}
}

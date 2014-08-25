// Created by Charles Greivelding
Shader "Antonov Suit/Specular Workflow/Transparent/Specular" 
{
	Properties 
	{
		_Color ("Diffuse Color", Color) = (1, 1, 1, 1)  
		_MainTex ("Diffuse (RGB)", 2D) = "white" {}
		
		_SpecColor ("Specular Color", Color) = (1, 1, 1, 1)   	 	
		_Shininess("Roughness", Range (0.001,1)) = 1.0
		_viewDpdtRoughness("View Dependent Roughness", Range (0.0,1)) = 0.0
		_toksvigFactor("Toksvig Factor", Range (0.0,1)) = 0.0
		_SpecTex ("Specular (RGB)", 2D) = "white" {}	
		
		_occlusionAmount ("Occlusion Amount", Range (0,1)) = 1.0
		
		_RGBTex ("Alpha (R), Roughness (G), Occlusion (B)", 2D) = "white" {}
			
		_BumpMap ("Normal", 2D) = "bump" {}

		_DiffCubeIBL ("Diffuse Cube", Cube) = "black" {}

		_SpecCubeIBL ("Specular Cube", Cube) = "black" {}
		
		_ENV_LUT ("Env BRDF LUT", 2D) = "white" {}
	}
	SubShader 
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 200
		
		ZWrite Off
      	Blend SrcAlpha OneMinusSrcAlpha
		
		CGINCLUDE
		#pragma target 3.0
		#pragma glsl
		#pragma vertex vert
		#pragma fragment frag
		#pragma only_renderers d3d9 opengl d3d11
		
		#include "UnityShaderVariables.cginc"
		
		//ANTONOV SUIT STUFF
		#pragma multi_compile ANTONOV_INFINITE_PROJECTION ANTONOV_SPHERE_PROJECTION ANTONOV_BOX_PROJECTION
		#pragma multi_compile _ ANTONOV_CUBEMAP_ATTEN
		
		#define ANTONOV_WORKFLOW_SPECULAR
		#define ANTONOV_DIFFUSE_LAMBERT
		#define ANTONOV_TOKSVIG
		#define ANTONOV_FRESNEL_GGX

		#include "../AntonovSuitInput.cginc"
		#include "../AntonovSuitLib.cginc"
		#include "../AntonovSuitBRDF.cginc"

		ENDCG
		
		Pass 
		{
			Name "FORWARD" 
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM

			//UNITY STUFF
			#pragma multi_compile_fwdbase 
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			
			//ANTONOV SUIT STUFF
			#define ANTONOV_FWDBASE
			
			#include "../AntonovSuitFrag.cginc"

			ENDCG
		}
		Pass 
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend SrcAlpha One

			CGPROGRAM
			
			//UNITY STUFF
			#pragma multi_compile_fwdadd_fullshadows
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			
			//ANTONOV SUIT STUFF
			#include "../AntonovSuitFrag.cginc"

			ENDCG
		}
	}
	FallBack "Transparent/Diffuse"
}

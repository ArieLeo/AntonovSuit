﻿// Created by Charles Greivelding
Shader "Antonov Suit/Metallic Workflow/Transparent/Cutout/Dielectric" 
{
	Properties 
	{
		_Color ("Base Color", Color) = (1, 1, 1, 1)
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_MainTex ("Base (RGB)", 2D) = "white" {}
 	
		_Shininess("Roughness", Range (0.001,1)) = 1.0
		_toksvigFactor("Toksvig Factor", Range (0.0,1)) = 0.0	
		
		_occlusionAmount ("Occlusion Amount", Range (0,1)) = 1.0
		_horyzonOcclusion("Horyzon Occlusion Amount", Range (0,1)) = 1.0
		
		_RGBTex ("Metallic (R), Roughness (G), Occlusion (B)", 2D) = "white" {}	
			
		_BumpMap ("Normal", 2D) = "bump" {}
		
		_DiffCubeIBL ("Diffuse Cube", Cube) = "black" {}

		_SpecCubeIBL ("Specular Cube", Cube) = "black" {}
		
		_ENV_LUT ("Env BRDF LUT", 2D) = "white" {}
	}
	SubShader 
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		LOD 200
		
		AlphaTest GEqual [_Cutoff]
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
		
		#define ANTONOV_WORKFLOW_METALLIC
		#define ANTONOV_DIELECTRIC
		#define ANTONOV_DIFFUSE_LAMBERT
		#define ANTONOV_TOKSVIG
		#define ANTONOV_HORYZON_OCCLUSION

		#include "../../AntonovSuitInput.cginc"
		#include "../../AntonovSuitLib.cginc"
		#include "../../AntonovSuitBRDF.cginc"

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
			
			#include "../../AntonovSuitFrag.cginc"

			ENDCG
		}
		Pass 
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			
			CGPROGRAM

			//UNITY STUFF
			#pragma multi_compile_fwdadd_fullshadows
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			
			//ANTONOV SUIT STUFF
			#include "../../AntonovSuitFrag.cginc"

			ENDCG
		}
	}
	FallBack "Transparent/Cutout/Diffuse"
}

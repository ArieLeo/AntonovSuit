// Created by Charles Greivelding

#ifndef ANTONOV_SUIT_INPUT_CGINC
#define ANTONOV_SUIT_INPUT_CGINC

//RGBM
bool _RGBM;

half4		_exposureIBL;

#ifdef ANTONOV_TOKSVIG
half		_toksvigFactor;
#endif

#if defined(ANTONOV_SPHERE_PROJECTION) || defined(ANTONOV_BOX_PROJECTION)
float4x4	_WorldToCube;
float4x4	_WorldToCubeInverse;
float		_cubemapScale;
float3		_cubemapPos;
float3		_cubemapBoxSize;
	#ifdef ANTONOV_CUBEMAP_ATTEN
		float		_attenSphereRadius;
		float3		_attenBoxSize;
	#endif
#endif

//LIGHTMAP
#ifdef LIGHTMAP_ON
float4 unity_LightmapST;
sampler2D unity_Lightmap;
	#ifdef DIRLIGHTMAP_ON
		sampler2D unity_LightmapInd;
	#endif
#endif	

//SKYLIGHT
samplerCUBE	_AmbCubeIBL;
float4		_skyColor;
float4		_groundColor;

//SKIN
#ifdef ANTONOV_SKIN
sampler2D	_SKIN_LUT;
sampler2D	_RGBSkinTex;
sampler2D	_BumpMicroTex;
sampler2D	_CavityMicroTex;
half		_tuneCurvature;
half		_cavityAmount;						
half		_BumpLod;												

half		_microBumpAmount;
half		_microBumpLod;
half		_microCavityAmount;
half		_microScale;
half		_tuneSkinCoeffX;
half		_tuneSkinCoeffY;
half		_tuneSkinCoeffZ;
#endif

//SELF ILLUM
#ifdef ANTONOV_ILLUM
sampler2D	_Illum;
half		_illumStrength;
half		_illumColorR;
half		_illumColorG;
half		_illumColorB;
#endif

//SPECULAR AND ROUGNESS
#ifdef ANTONOV_WORKFLOW_SPECULAR
sampler2D	_SpecTex;
//fixed4		_SpecColor; Built in
#endif

#ifdef ANTONOV_WORKFLOW_METALLIC

#endif

//METALLIC ROUGHNESS AND OCCLUSION
#if defined (ANTONOV_WORKFLOW_METALLIC) || defined(ANTONOV_SKIN) || defined(ANTONOV_WORKFLOW_SPECULAR)
sampler2D	_RGBTex;
#endif
half		_Shininess;
half		_viewDpdtRoughness;
half		_occlusionAmount;
			
//BASE COLOR AND DIFFUSE
sampler2D	_MainTex;
float4		_MainTex_ST;
fixed4		_Color;

//NORMAL
sampler2D	_BumpMap;

int		_diffSamples;
int		_specSamples;

//DIFFUSE IBL
samplerCUBE _DiffCubeIBL;
int 		_diffuseSize;
		
//SPECULAR IBL
samplerCUBE _SpecCubeIBL;	
sampler2D	_ENV_LUT;
int 		_specularSize;
int 		_lodSpecCubeIBL;

//HORYZON OCCLUSION
half		_horyzonOcclusion;

#endif
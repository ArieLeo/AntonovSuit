// Sub Surface Scattering Shader based on Eric Penner - Siggraph 2011 – Advances in Real-Time Rendering
// Created by Charles Greivelding

Shader "Antonov Suit/Skin/PreIntegrated Skin" 
{
	Properties 
	{
		_Color ("Base Color", Color) = (1, 1, 1, 1)  
		_MainTex ("Base (RGB)", 2D) = "white" {}
		
		_tuneSkinCoeffX ("Skin Coeffient R", Range (0,1)) = 1.0
		_tuneSkinCoeffY ("Skin Coeffient G", Range (0,1)) = 0.5
		_tuneSkinCoeffZ ("Skin Coeffient B", Range (0,1)) = 0.25
		_BumpLod ("Skin Softness", Range (0,1)) = 1.0
		_tuneCurvature ( "Skin Scattering", Range (0,1)) = 0.2
		_SKIN_LUT ("Skin BRDF LUT", 2D) = "" {}
		 	
		_Shininess("Roughness", Range (0.01,1)) = 1.0
			
		_occlusionAmount ("Occlusion Amount", Range (0,1)) = 1.0
		
		_RGBTex ("Roughness (G), Occlusion (B)", 2D) = "white" {}
			
		_cavityAmount ("Cavity Amount", Range (0,1)) = 1.0
		
		_RGBSkinTex ("Cavity (R), Curvature (G), Thickness (B)", 2D) = "white" {}
		
		
		_BumpMap ("Normal", 2D) = "bump" {}
		
		_microScale("Micro Scale", Float) = 8.0
		_microCavityAmount("Micro Cavity Amount", Float) = 1.0
		_CavityMicroTex ("Micro Cavity", 2D) = "white" {}

		_microBumpAmount ("Micro Bump Amount", Float) = 1.0
		_BumpMicroTex ("Micro Bump", 2D) 	= "bump" {}

		_DiffCubeIBL ("Diffuse Cube", Cube) = "black" {}

		_SpecCubeIBL ("Specular Cube", Cube) = "black" {}
		
		_ENV_LUT ("Env BRDF LUT", 2D) = "white" {}
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGINCLUDE
		#pragma target 3.0
		#pragma glsl
		#pragma vertex vert
		#pragma fragment frag
		#pragma only_renderers d3d9 opengl d3d11
		
		#include "UnityShaderVariables.cginc"

		//ANTONOV SUIT STUFF
		#pragma multi_compile ANTONOV_INFINITE_PROJECTION ANTONOV_SPHERE_PROJECTION ANTONOV_BOX_PROJECTION
		
		#define ANTONOV_SKIN
		#define ANTONOV_FRESNEL_BLINN
		
		#include "AntonovSuitInput.cginc"
		#include "AntonovSuitLib.cginc"
		#include "AntonovSuitBRDF.cginc"

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

			struct v2f 
			{
			    float4	pos 		: POSITION;
			    //float4	screenPos	: TEXCOORD0;
			    float3	normal		: TEXCOORD1;
			    float4	worldPos	: TEXCOORD2;
			    float2	uv			: TEXCOORD3;
			    LIGHTING_COORDS(5,6)
				float3 	TtoW0		: TEXCOORD7;
				float3 	TtoW1		: TEXCOORD8;
				float3 	TtoW2		: TEXCOORD9;
				float3 	lightDir 	: TEXCOORD0;
			};
			
			v2f vert(appdata_tan v)
			{
			    v2f o;
			    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			   	o.worldPos = mul(_Object2World, v.vertex);
			   	o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
			   	o.lightDir = mul(_Object2World,float4(ObjSpaceLightDir(v.vertex),0));
			    o.normal =  mul(_Object2World, float4(v.normal, 0)).xyz;
			    TANGENT_SPACE_ROTATION;
				o.TtoW0 = mul(rotation, _Object2World[0].xyz * unity_Scale.w);
				o.TtoW1 = mul(rotation, _Object2World[1].xyz * unity_Scale.w);
				o.TtoW2 = mul(rotation, _Object2World[2].xyz * unity_Scale.w);	 
				//SHADOW
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			
			half4 frag( v2f i ) : COLOR
			{
				#define uv_metallic i.uv
				#define uv_base i.uv
				#define uv_diff i.uv
				#define uv_spec i.uv
				#define uv_bump i.uv
				#define uv_occlusion i.uv
			
				//Basic stuff
				float3 white = float3(1.0,1.0,1.0);
				float3 black = float3(0.0,0.0,0.0);
			
			    //float2 screenCoord = i.screenPos.xy / i.screenPos.w;
			    
			    //METALLIC
				float metallic = tex2D(_RGBTex, uv_metallic).x;
			    
			    //OCCLUSION
				float occlusion = float(1.0f);
			
				occlusion = tex2D( _RGBTex, uv_occlusion ).z;
				occlusion = lerp(white,occlusion,_occlusionAmount);
				
				fixed atten = LIGHT_ATTENUATION(i);
			
			    float4 worldPos = i.worldPos;
			    
			    float3 viewDir = normalize( i.worldPos - _WorldSpaceCameraPos );
			  
			    float3 lightColor = _LightColor0.rgb * 2;
			    
				float3 lightDir = normalize(i.lightDir);	
				
				float3 h = (-viewDir)+lightDir;	
				float3 halfVector = normalize(h);
					    
			    //BASE COLOR
				float4 baseColor = tex2D(_MainTex, uv_base);
				baseColor.rgb *= _Color.rgb;
				
				//ROUGHNESS
				float roughness = tex2D(_RGBTex, uv_metallic).y;
				roughness *= _Shininess;
				roughness = roughness;
				
				//CAVITY
				float cavity =  tex2D( _RGBSkinTex, uv_base ).x;
				cavity = lerp(1.0f, cavity, _cavityAmount);

				//NORMAL
				float3 normal = UnpackNormal(tex2D(_BumpMap, uv_diff));
				
				float3 vertexNormal = float3(0,0,1); // Z-Up Vertex tangent space normal

				float3 microNormal = UnpackNormal(tex2D(_BumpMicroTex,uv_bump*_microScale));
				microNormal = lerp(vertexNormal,microNormal,_microBumpAmount);
										
				normal.xy += microNormal.xy;

				float3 worldNormal = float3(0,0,0);
				worldNormal.x = dot(i.TtoW0, normal);
				worldNormal.y = dot(i.TtoW1, normal);
				worldNormal.z = dot(i.TtoW2, normal);
			
				worldNormal = normalize(worldNormal);

				//VERTEX NORMAL
				//vertexNormal = UnpackNormal(tex2Dlod(_BumpMap, float4(uv_bump,0,_BumpLod*14))); // Tangent space normal
				
				float3 worldVertexNormal = float3(0,1,0);
				worldVertexNormal.x = dot(i.TtoW0, vertexNormal);
				worldVertexNormal.y = dot(i.TtoW1, vertexNormal);
				worldVertexNormal.z = dot(i.TtoW2, vertexNormal);
			
				worldVertexNormal = normalize(worldVertexNormal);
				
				float3 blurredNormal = lerp(worldNormal,worldVertexNormal,_BumpLod);
				
				//MICRO CAVITY
				float microCavity = tex2D( _CavityMicroTex, uv_base*_microScale).x;
				microCavity = saturate(lerp(1.0f,microCavity,_microCavityAmount));

				// CURVATURE
				float curvature = tex2D(_RGBSkinTex,uv_base).y * _tuneCurvature;
				
				//VECTORS
				float NdotL = saturate( dot( worldNormal, lightDir ) );
				//half HalfLambert = saturate( dot( worldNormal, lightDir ) * _BumpLod + _BumpLod );
				float NdotV = saturate( dot( worldNormal, -viewDir ) );
				float NdotH = saturate( dot( worldNormal, halfVector ) );
				float LdotH = saturate( dot( lightDir, halfVector ) );
				float VdotH = saturate( dot( -viewDir, halfVector ) );
				
				//SHADOWS
				float3 skinShadow = tex2D( _SKIN_LUT,float2(atten,.9999));
				
				//DIFFUSE
				float4 diffuse = baseColor;

				float3 diffuseLambert = PennerSkin( float3( _tuneSkinCoeffX,_tuneSkinCoeffY,_tuneSkinCoeffZ ), worldNormal,lightDir, blurredNormal, curvature, _SKIN_LUT, atten )  * lightColor * skinShadow;

			    //SPECULAR
			   	float4 specular = half4(0.028,0.028,0.028,1) * cavity * microCavity;

				float D = D_Beckmann(roughness, NdotH);
				
				float3 F = F_Schlick( specular, VdotH );
					
				float3 specularDirect = max( D * F / dot( h, h ), 0 ) * NdotL * lightColor * atten;
				
				//SPECULAR IBL
				half3 specularIBL = ApproximateSpecularIBL( specular.rgb, roughness, worldNormal, -viewDir, i.worldPos ) * _exposureIBL.x;

				//DIFFUSE IBL
				float3 diffuseIBL = diffuseSkinIBL(float3(_tuneSkinCoeffX, _tuneSkinCoeffY, _tuneSkinCoeffZ), ApproximateDiffuseIBL(worldNormal).rgb, ApproximateDiffuseIBL(blurredNormal).rgb) * _exposureIBL.y;

				float3 ambient = UNITY_LIGHTMODEL_AMBIENT;

				float4 frag = float4(0,0,0,1);

				frag.rgb = ( diffuseLambert + diffuseIBL + ambient ) * diffuse * occlusion;
				
				frag.rgb += ( specularDirect + specularIBL )* occlusion;
	
				return frag;
			}
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

			struct v2f 
			{
			    float4	pos 		: POSITION;
			    //float4	screenPos	: TEXCOORD0;
			    float3	normal		: TEXCOORD1;
			    float4	worldPos	: TEXCOORD2;
			    float2	uv			: TEXCOORD3;
			    LIGHTING_COORDS(5,6)
				float3 	TtoW0		: TEXCOORD7;
				float3 	TtoW1		: TEXCOORD8;
				float3 	TtoW2		: TEXCOORD9;
				float3 	lightDir 	: TEXCOORD0;
			};
			
			v2f vert(appdata_tan v)
			{
			    v2f o;
			    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			   	o.worldPos = mul(_Object2World, v.vertex);
			   	o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
			   	o.lightDir = mul(_Object2World,float4(ObjSpaceLightDir(v.vertex),0));
			   // o.screenPos = ComputeScreenPos(o.pos);;
			    o.normal =  mul(_Object2World, float4(v.normal, 0)).xyz;
			    TANGENT_SPACE_ROTATION;
				o.TtoW0 = mul(rotation, _Object2World[0].xyz * unity_Scale.w);
				o.TtoW1 = mul(rotation, _Object2World[1].xyz * unity_Scale.w);
				o.TtoW2 = mul(rotation, _Object2World[2].xyz * unity_Scale.w);	 
				//SHADOW
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			
			half4 frag( v2f i ) : COLOR
			{
				#define uv_metallic i.uv
				#define uv_base i.uv
				#define uv_diff i.uv
				#define uv_spec i.uv
				#define uv_bump i.uv
				#define uv_occlusion i.uv
			
				//Basic stuff
				float3 white = float3(1.0,1.0,1.0);
				float3 black = float3(0.0,0.0,0.0);
			
			    //float2 screenCoord = i.screenPos.xy / i.screenPos.w;
			    
			    //METALLIC
				float metallic = tex2D(_RGBTex, uv_metallic).x;
			    
			    //OCCLUSION
				float occlusion = float(1.0f);
			
				occlusion = tex2D( _RGBTex, uv_occlusion ).z;
				occlusion = lerp(white,occlusion,_occlusionAmount);
				
				float atten = LIGHT_ATTENUATION(i);
			
			    float4 worldPos = i.worldPos;
			    
			    float3 viewDir = normalize( i.worldPos - _WorldSpaceCameraPos );
			  
			    float3 lightColor = _LightColor0.rgb * 2;
			    
				float3 lightDir = normalize(i.lightDir);	
				
				float3 h = -viewDir+lightDir;	
				float3 halfVector = normalize(h);
				
			    
			    //BASE COLOR
				float4 baseColor = tex2D(_MainTex, uv_base);
				baseColor.rgb *= _Color.rgb;
				
				//ROUGHNESS
				float roughness = tex2D(_RGBTex, uv_metallic).y;
				roughness *= _Shininess;
				roughness = roughness;
				
				//CAVITY
				float cavity =  tex2D( _RGBSkinTex, uv_base ).x;
				cavity = lerp(1.0f, cavity, _cavityAmount);

				//NORMAL
				float3 normal = UnpackNormal(tex2D(_BumpMap, uv_diff));
				
				float3 vertexNormal = float3(0,0,1); // Z-Up Vertex tangent space normal

				float3 microNormal = UnpackNormal(tex2D(_BumpMicroTex,uv_bump*_microScale));
				microNormal = lerp(vertexNormal,microNormal,_microBumpAmount);
										
				normal.xy += microNormal.xy;
				
				float3 worldNormal = float3(0,0,0);
				worldNormal.x = dot(i.TtoW0, normal);
				worldNormal.y = dot(i.TtoW1, normal);
				worldNormal.z = dot(i.TtoW2, normal);
			
				worldNormal = normalize(worldNormal);
				
				//VERTEX NORMAL
				//vertexNormal = UnpackNormal(tex2Dlod(_BumpMap, float4(uv_bump,0,_BumpLod*14))); // Tangent space normal
				
				float3 worldVertexNormal = float3(0,1,0);
				worldVertexNormal.x = dot(i.TtoW0, vertexNormal);
				worldVertexNormal.y = dot(i.TtoW1, vertexNormal);
				worldVertexNormal.z = dot(i.TtoW2, vertexNormal);
			
				worldVertexNormal = normalize(worldVertexNormal);
				
				float3 blurredNormal = lerp(worldNormal,worldVertexNormal,_BumpLod);
				
				//MICRO CAVITY
				float microCavity = tex2D( _CavityMicroTex, uv_base*_microScale).x;
				microCavity = saturate(lerp(1.0f,microCavity,_microCavityAmount));

				// CURVATURE
				float curvature = tex2D(_RGBSkinTex,uv_base).y * _tuneCurvature;
				
				//VECTORS
				float NdotL = saturate( dot( worldNormal, lightDir ) );
				float NdotV = saturate( dot( worldNormal, -viewDir ) );
				float NdotH = saturate( dot( worldNormal, halfVector ) );
				float LdotH = saturate( dot( lightDir, halfVector ) );
				float VdotH = saturate( dot( -viewDir , halfVector ) );
				
				//SHADOWS
				//float3 skinShadow = tex2D( _SKIN_LUT,float2(atten*2,1));
				
				//DIFFUSE
				float4 diffuse = baseColor;

				float3 diffuseLambert = PennerSkin( float3( _tuneSkinCoeffX,_tuneSkinCoeffY,_tuneSkinCoeffZ ), worldNormal,lightDir, blurredNormal, curvature, _SKIN_LUT, atten )  * lightColor * atten;

			    //SPECULAR
			   	float4 specular = half4(0.028,0.028,0.028,1) * cavity * microCavity;

				float D = D_Beckmann(roughness, NdotH);
				
				float3 F = F_Schlick( specular, VdotH );
					
				float3 specularDirect = max( D * F / dot( h, h ), 0 ) * NdotL * lightColor * atten;

				float4 frag = float4(0,0,0,1);

				frag.rgb = diffuseLambert * diffuse * occlusion;
				
				frag.rgb += specularDirect * occlusion;
	
				return frag;
			}
			ENDCG
		}
	
	}
	FallBack "Diffuse"
}

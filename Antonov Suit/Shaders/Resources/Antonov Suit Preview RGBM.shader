// Created by Charles Greivelding
Shader "Hidden/Antonov Suit/Probe" 
{
	Properties 
	{
		_DiffCubeIBL ("Diffuse Cube", Cube) = "black" {}
		_SpecCubeIBL ("Specular Cube", Cube) = "black" {}
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

				
		half4		_exposureIBL;
		samplerCUBE _SpecCubeIBL;
		samplerCUBE _DiffCubeIBL;	


		#include "../AntonovSuitLib.cginc"

		ENDCG
		
		Pass 
		{

			
			CGPROGRAM

			//UNITY STUFF
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

			struct v2f 
			{
			    float4	pos 		: POSITION;
			    float3	normal		: TEXCOORD1;
			    float4	worldPos	: TEXCOORD2;
			};
			
			v2f vert(appdata_full v)
			{
			    v2f o;
			    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			   	o.worldPos = mul(_Object2World, v.vertex);
			    o.normal =  mul(_Object2World, float4(v.normal, 0)).xyz;
				return o;
			}
			
			half4 frag( v2f i ) : COLOR
			{
				
			    float4 worldPos = i.worldPos;
			    
			    float3 normal = normalize(i.normal);
			    
			    half3 viewDir = normalize( i.worldPos - _WorldSpaceCameraPos );
			    viewDir = -viewDir; 
			    
			    float3 worldRefl = 2 * dot(viewDir, normal) * normal -  viewDir;
			    
			    float maskIBL = saturate(dot(normal, float3(0, 0, 1)) * 1000);
			    
			    float maskMIP = 1-saturate(dot(normal, float3(0, 1, 0)) * 1000);

				float4 frag	= float4(0, 0, 0, 1);

				float3 specularIBL = DecodeRGBMLinear(texCUBElod(_SpecCubeIBL, float4(worldRefl, maskMIP*2))) * _exposureIBL.x;
				 
				float3 diffuseIBL = DecodeRGBMLinear(texCUBE(_DiffCubeIBL, normal)) * _exposureIBL.y;
				  
				frag.rgb = lerp(specularIBL, diffuseIBL, maskIBL);
				
				return frag;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}

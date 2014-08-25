Shader "Hidden/Antonov Suit/Radiance/GGX" 
{
	Properties 
	{
		_Shininess("Roughness", Range (0.001,1)) = 1.0
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

			#include "UnityCG.cginc"
			#include "../../AntonovSuitInput.cginc"
			#include "../../AntonovSuitLib.cginc"
			#include "../../AntonovSuitBRDF.cginc"
			
			struct data 
			{
			    float4 vertex : POSITION;
			    float3 normal : NORMAL;
			};
			
			struct v2f 
			{
			    float4	vertex 		: POSITION;
			    float3	texcoord			: TEXCOORD3;
			};
			
			v2f vert(appdata_tan v)
			{
			    v2f o;
			    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
			   	o.texcoord = v.texcoord;
				return o;
			}
			
			half4 frag( v2f i ) : COLOR
			{
				float3 normal = normalize(i.texcoord);

				float4 frag = float4(0,0,0,1);
			
				frag.rgb = SpecularIBL( _Shininess, normal);
				
				return frag;
			}
			ENDCG
		}
	}
}

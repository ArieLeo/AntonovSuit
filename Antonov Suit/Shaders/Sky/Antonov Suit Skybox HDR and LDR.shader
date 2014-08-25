// Created by Charles Greivelding
Shader "Antonov Suit/Sky/Skybox HDR and LDR" 
{
Properties 
{
	_Exposure ("Sky Exposure", float) = 1
	_SkyCubeIBL ("SkyCube", Cube) = "white" {}
}

SubShader {
	Tags { "Queue"="Background" "RenderType"="Background" }
	Cull Off ZWrite Off Fog { Mode Off }

	Pass {
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma target 3.0

		#include "UnityCG.cginc"
		#include "../AntonovSuitLib.cginc"

		samplerCUBE _SkyCubeIBL;
		
		float	_Exposure;
		
		struct appdata_t {
			float4 vertex : POSITION;
			float3 texcoord : TEXCOORD0;
		};

		struct v2f {
			float4 vertex : POSITION;
			float3 texcoord : TEXCOORD0;
		};

		v2f vert (appdata_t v)
		{
			v2f o;
			o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
			o.texcoord = v.texcoord;
			return o;
		}

		float4 frag (v2f i) : COLOR
		{
			float4 frag = float4(0,0,0,1);
			
			float3 sky = DecodeRGBMLinearREA(texCUBE (_SkyCubeIBL, i.texcoord)).rgb * _Exposure;

			frag.rgb = sky.rgb;
			
			return frag;
		}
		ENDCG 
	}
} 	


Fallback Off

}

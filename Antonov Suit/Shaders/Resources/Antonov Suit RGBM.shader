Shader "Hidden/RGBM" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "black" {}		
	}

CGINCLUDE

#include "UnityCG.cginc"
#include "../AntonovSuitLib.cginc"

struct v2f {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD0;
};

sampler2D _MainTex;
float4		_MainTex_TexelSize;


v2f vert( appdata_img v ) 
{
	v2f o;
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	o.uv =  v.texcoord.xy;	
	return o;
} 

float4 frag(v2f i) : COLOR 
{

	float4 frag = HDRtoRGBM(tex2D(_MainTex, i.uv));
	
	frag.rgb = pow(frag.rgb,1/2.2);

	return frag;
}


ENDCG 

	
Subshader 
{
	Pass 
	{
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
	  #pragma target 2.0
      ENDCG
  	}

}
Fallback off
}

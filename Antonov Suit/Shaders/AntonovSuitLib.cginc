// Created by Charles Greivelding

#ifndef ANTONOV_SUIT_LIB_CGINC
#define ANTONOV_SUIT_LIB_CGINC


float4 HDRtoRGBM(float4 color)
{
	float toLinear = 2.2;
	float toSRGB = 1/2.2;
	color.rgb = pow(color.rgb, toSRGB);
	fixed MaxRange = 8;
    float maxRGB = max( color.x, max( color.g, color.b ) );
    float M = maxRGB / MaxRange;
    M = ceil( M * 255.0 ) / 255.0;
    color = float4( color.rgb / ( M * MaxRange ), M );
    
    color.rgb = pow(color.rgb, toLinear);
    
    return color;
}

float3 DecodeRGBMGamma(float4 rgbm)
{
	float MaxRange = 8;
	return (rgbm.rgb*rgbm.rgb) * rgbm.a * MaxRange;
}
			
float3 DecodeRGBMLinear(float4 rgbm)
{
	float toLinear = 2.2;
	float MaxRange = pow(8,toLinear);
	return rgbm.rgb * pow(rgbm.a,toLinear) * MaxRange;
}	

// Gives better hdr response, thanks to Rea from Unity forum community
float3 DecodeRGBMLinearREA(float4 rgbm)
{
	float toLinear = 2.2f;
	float MaxRange = pow(8,toLinear);
	
	float m = rgbm.a;
	float m2 = pow(m, toLinear);
	
	float lin_m = dot(float2(0.7532f, 0.2468f), float2(m2, m2 * m));
	 
	return rgbm.rgb * lin_m * MaxRange;
}	

// http://blog.selfshadow.com/publications/blending-in-detail/
float3 blend_rnm(float4 n1, float3 n2)
{
    float3 t = n1.xyz*float3( 2,  2, 2) + float3(-1, -1,  0);
    float3 u = n2.xyz*float3(-2, -2, 2) + float3( 1,  1, -1);
    float3 r = t*dot(t, u) - u*t.z;
	return r;
}

float3 rnmBlendUnpacked(float3 n1, float3 n2)
{
    n1 += float3( 0,  0, 1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}

float RoughnessToSpecPower(in float m) 
{
	float m2 = m * m;
    return 2.0f / (m * m) - 2.0f;
}

float SpecPowerToRoughness(in float s) 
{
    return sqrt(2.0f / (s + 2.0f));
}

float Toksvig(float3 bump, float roughness)
{
	float3 normalMapLen = fwidth(bump);
	
	float s = RoughnessToSpecPower(roughness);
	
	float ft = normalMapLen / lerp(s, 1.0f, normalMapLen);
	ft = max(ft, 0.01f);
	roughness = SpecPowerToRoughness(ft * s);
	
	return roughness;
}

float4 gaussianBlurX( sampler2D tex, float2 uv, float2 texSize, float size )
{
	float blurXY = size / texSize.x;
					
	float4 sum = float4(0,0,0,1);
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x - 4.0	*	blurXY, uv.y))) * 0.05;   
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x - 3.0	*	blurXY, uv.y))) * 0.09;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x - 2.0	*	blurXY, uv.y))) * 0.12;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x - 			blurXY, uv.y))) * 0.15;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x					  , uv.y))) * 0.16;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x + 			blurXY, uv.y))) * 0.15;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x + 2.0	*	blurXY, uv.y))) * 0.12;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x + 3.0	*	blurXY, uv.y))) * 0.09;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x + 4.0	*	blurXY, uv.y))) * 0.05;
			 
	return HDRtoRGBM(sum);
}
				
float4 gaussianBlurY( sampler2D tex, float2 uv, float2 texSize, float size )
{
	float blurXY = size / texSize.y;
					
	float4 sum = float4(0,0,0,1);
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y - 4.0	*	blurXY))) * 0.05;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y - 3.0	*	blurXY))) * 0.09;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y - 2.0	*	blurXY))) * 0.12;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y - 			blurXY))) * 0.15;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y				  ))) * 0.16;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y +			blurXY))) * 0.15;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y + 2.0	*	blurXY))) * 0.12;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y + 3.0	*	blurXY))) * 0.09;
	sum.rgb += DecodeRGBMLinear(tex2D(tex, float2(uv.x,uv.y + 4.0	*	blurXY))) * 0.05;
			 
	return HDRtoRGBM(sum);
}

// Occlusion taking into account the color of the texture multiply to it
float3 coloredOcclusion(float3 color, float occlusion)
{
	float3 coloredOcclusion = lerp( float3( 1.0f, 1.0f, 1.0f ), color,( 1 - occlusion ) );
	//color *= coloredOcclusion;
	return coloredOcclusion;
}

// http://the-witness.net/news/2012/02/seamless-cube-map-filtering/
float3 fix_cube_lookup(float3 v, float Roughness ,int mipMap) 
{
   float M = max(max(abs(v.x), abs(v.y)), abs(v.z));
	float scale = 1 - Roughness / mipMap;
	if (abs(v.x) != M) v.x *= scale;
	if (abs(v.y) != M) v.y *= scale;
	if (abs(v.z) != M) v.z *= scale;
   return v;
}

float specularOcclusion( float3 N, float3 V, float Occlusion )
{
	const float specularPow = 5.0;
	float NdotV = dot(N, V);
	float s = saturate(-0.3 + NdotV * NdotV);
	
	return lerp(pow(Occlusion, specularPow),1.0, s);
}

#endif

// Created by Charles Greivelding

#ifndef ANTONOV_SUIT_BRDF_CGINC
#define ANTONOV_SUIT_BRDF_CGINC

#define PI 3.14159265359

inline float sqr(float x) 
{ 
	return x*x; 
}

// Brent, Burley, "Physically-Based Shading at Disney", 2012
inline float Burley( float NdotL, float NdotV, float VdotH, float Roughness )
{
	float F_D90 = 0.5 + 2 * VdotH * VdotH * Roughness;
	return ( 1 + ( F_D90 - 1) * pow(( 1 - NdotL ),5.0) ) * ( 1 + ( F_D90 - 1) * pow(( 1 - NdotV ),5.0) );
}

// [Beckmann 1963, "The scattering of electromagnetic waves from rough surfaces"]
inline float D_Beckmann( float Roughness, float NoH )
{
	float m = Roughness;
	float m2 = m * m;
	float NdotH2 = sqr(NoH);
	return exp( (NdotH2 - 1) / (m2 * NdotH2) ) / ( PI * m2 * NdotH2 * NdotH2 );
}

// David Neubelt and Matt Pettineo, Ready at Dawn Studios, "Crafting a Next-Gen Material Pipeline for The Order: 1886", 2013
inline float D_GGX(float Roughness, float NdotH)
{
	float m = Roughness;
	float m2 = m*m;
	float D = m2 / (PI * sqr(sqr(NdotH) * (m2 - 1) + 1));
	
	return D;
}

// Bruce Walter, Stephen R. Marschner, Hongsong Li, and Kenneth E. Torrance. Microfacet models forrefraction through rough surfaces. In Proceedings of the 18th Eurographics conference on RenderingTechniques, EGSR'07
inline float G_GGX(float Roughness, float NdotL, float NdotV)
{
	float m = Roughness;
	float m2 = m*m;

	float G_L = 1.0f / (NdotL + sqrt(m2 + (1 - m2) * NdotL * NdotL));
	float G_V = 1.0f / (NdotV + sqrt(m2 + (1 - m2) * NdotV * NdotV));
	float G = G_L * G_V;
	
	return G;
}

// Kelemen 2001 "A Microfacet Based Coupled Specular-Matte BRDF Model with Importance Sampling"
inline float G_Kelemenn( float NdotL, float NdotV, float LdotV)
{

    float G = NdotL * NdotV * 2 / (1 + LdotV);
    
    return G;
}
	
// Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"	
inline float G_Schlick(float Roughness, float NdotV, float NdotL)
{
	float m = Roughness;
	//float m = roughness*roughness;
	float m2 = m*m;
	return (NdotV * NdotL) / ( (NdotV * (1 - m) + m) * (NdotL * (1 - m) + m) );
}

// Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
// Lagarde 2012, "Spherical Gaussian approximation for Blinn-Phong, Phong and Fresnel"
inline float3 F_Schlick(float3 SpecularColor,float LdotH)
{
    return SpecularColor + ( 1.0f - SpecularColor ) * exp2( (-5.55473 * LdotH - 6.98316) * LdotH );
}

// Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
// Lagarde 2011, "Adopting a physically based shading model"
// Lagarde 2012, "Spherical Gaussian approximation for Blinn-Phong, Phong and Fresnel"
inline float3 F_LagardeSchlick(float3 SpecularColor,float Roughness, float NdotV)
{
    return SpecularColor + ( max(1 - Roughness, SpecularColor) - SpecularColor )  * exp2( (-5.55473 * NdotV - 6.98316) * NdotV );
}

// Dimitar Lazarov "Getting More Physical in Call of Duty: Black Ops II", SigGraph 2013
inline float3 F_Lazarov( float g, float3 rf0,float3 Normal, float3 ViewVector )
{
	float NdotV = saturate( dot( Normal, ViewVector ) );

	float4 t = float4( 1/0.96, 0.475, (0.0275 - 0.25 * 0.04)/0.96, 0.25 );
	t *= float4( g, g, g, g );
	t += float4( 0, 0, (0.015 - 0.75 * 0.04)/0.96, 0.75 );
	float a0 = t.x * min( t.y, exp2( -9.28 * NdotV ) ) + t.z;
	float a1 = t.w;
	return saturate( a0 + rf0 * ( a1 - a0 ) );
}

// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
// Changed by EPIC
inline half3 F_LazarovApprox( half3 SpecularColor, half Roughness, half NoV )
{
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
	half4 r = Roughness * c0 + c1;
	half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

	return SpecularColor * AB.x + AB.y;
}

float3 PennerSkin(float3 skinCoef, float3 N,float3 L, float3 Nlow, float Curvature, sampler2D _LookUp, float Shadow )
{	
	float3 pennerX = lerp( N, Nlow, skinCoef.x ); 
	float3 pennerY = lerp( N, Nlow, skinCoef.y );
	float3 pennerZ = lerp( N, Nlow, skinCoef.z );
			
	float3 pennerNdotL = float3( dot( pennerX, L ), dot( pennerY, L ), dot( pennerZ, L ) );
	pennerNdotL = saturate( pennerNdotL * 0.5 + 0.5 );
	// Adding shadow into the lookup
	//pennerNdotL *= Shadow;
	
	float3 pennerlookUp;
	//float brdf = Curvature * dot( _LightColor0.rgb, skinCoef );
	pennerlookUp.r = tex2D( _LookUp, float2( pennerNdotL.r, Curvature ) ).r;
	pennerlookUp.g = tex2D( _LookUp, float2( pennerNdotL.g, Curvature ) ).g;
	pennerlookUp.b = tex2D( _LookUp, float2( pennerNdotL.b, Curvature ) ).b;
	
	return pennerlookUp;
}

//
inline float3 diffuseSkinIBL(float3 skinCoef, float3 diffuseIBL_HighFreq, float3 diffuseIBL_LowFreq)
{
	return lerp(diffuseIBL_HighFreq , diffuseIBL_LowFreq, skinCoef);
}

inline float RadicalInverse( int n, int base)
{
	float bits = 0.0f;
	float invBase = 1.0f / base, invBi = invBase;
 	while (n > 0) 
	{
	  	int d_i = (n % base);
		bits += d_i * invBi;
		n /= base;
		invBi *= invBase;
	}
	return (bits);
}

inline float2 Hammersley(int i, int N)
{
	return float2(float(i) * (1.0/float( N )), RadicalInverse(i,3) );
}


// we can get away with 32 samples with a 256x256 cubemap
inline float calcLOD(int size, float pdf, int NumSamples)
{
	// log2(w*h)/N
	float preCalcLod = log2( (size*size) / NumSamples);
	return 0.5 * preCalcLod - 0.5 * log2( pdf );
}
			
inline float4 ImportanceSampleIrradiance( float2 Xi,float3 N)
{
			   
	//float r = sqrt(Xi.x*Xi.x+Xi.y*Xi.y); 
	//float theta = PI*r;
				
	//float phi = 2 * PI * Xi.x;
				
	//float x = sin(theta)*cos(phi);
	//float y = sin(theta)*sin(phi);
	//float z = cos(theta);
				
	float Phi = 2 * PI * Xi.x;
	float CosTheta = 1 - 2 * Xi.y;
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	float pdf = 1.0 / (4 * PI);

	float3 UpVector = float3(0,1,0);
	float3 T = normalize( cross( UpVector, N ) );
	float3 B = cross( N, T );
			 
	return float4((T * H.x) + (B * H.y) + (N * H.z), pdf); 
}

// http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html	
inline float4 ImportanceSampleSphereUniform( float2 Xi,float3 N)
{			
	float Phi = 2 * PI * Xi.x;
	float CosTheta = 1 - 2 * Xi.y;
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	float pdf = 1.0 / (4 * PI);

	float3 UpVector = float3(0,1,0);
	float3 T = normalize( cross( UpVector, N ) );
	float3 B = cross( N, T );
			 
	return float4((T * H.x) + (B * H.y) + (N * H.z), pdf); 
}
	
inline float4 ImportanceSampleHemisphereUniform( float2 Xi, float3 N)
{
	float Phi = 2 * PI * Xi.x;
	float CosTheta = Xi.y;
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	float pdf = 1.0 / (2 * PI);

	float3 UpVector = float3(0,1,0);
	float3 T = normalize( cross( UpVector, N ) );
	float3 B = cross( N, T );
			 
	return float4((T * H.x) + (B * H.y) + (N * H.z), pdf); 
}

inline float4 ImportanceSampleHemisphereCosine( float2 Xi, float3 N)
{
	float Phi = 2 * PI * Xi.x;
	float CosTheta = sqrt(Xi.y);
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	float pdf = CosTheta / PI;

	float3 UpVector = float3(0,1,0);
	float3 T = normalize( cross( UpVector, N ) );
	float3 B = cross( N, T );
			 
	return float4((T * H.x) + (B * H.y) + (N * H.z), pdf); 
}
			
inline float4 ImportanceSampleBlinn( float2 Xi, float Roughness, float3 N )
{
	float m = Roughness;
	float m2 = m*m;
	
	float n = 2 / (m2) - 2;

	float Phi = 2 * PI * Xi.x;
	float CosTheta = pow( max(Xi.y, 0.001f), 1 / (n + 1) );
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	float D = (n+2)/ (2*PI) * saturate(pow( CosTheta, n ));
	float pdf = D * CosTheta;

	float3 UpVector = float3(0,1,0);
	float3 T = normalize( cross( UpVector, N ) );
	float3 B = cross( N, T );
	

	return float4((T * H.x) + (B * H.y) + (N * H.z), pdf);
}

// Brian Karis, Epic Games "Real Shading in Unreal Engine 4"
inline float4 ImportanceSampleGGX( float2 Xi, float Roughness, float3 N)
{
	float m = Roughness;
	float m2 = m*m;
	
	float Phi = 2 * PI * Xi.x;
			 
	float CosTheta = sqrt( (1 - Xi.y) / ( 1 + (m2 - 1) * Xi.y ) );
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );  
			 
	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	float d = ( CosTheta * m2 - CosTheta ) * CosTheta + 1;
	float D = m2 / ( PI*d*d );
	float pdf = D * CosTheta;
			 
 	float3 UpVector = float3(0,1,0);
	float3 T = normalize( cross( UpVector, N ) );
	float3 B = cross( N, T );
			 
	return float4((T * H.x) + (B * H.y) + (N * H.z), pdf);
}

// Brian Karis, Epic Games "Real Shading in Unreal Engine 4"
float3 DiffuseIBL(float3 R)
{
			
	float3 N = R;
	float3 V = R;
				
	float4 SampleColor = 0;
	float TotalWeight = 0;
	const int NumSamples = _diffSamples;
	
	for( int i = 0; i < NumSamples; i++ )
	{
		float2 Xi = Hammersley( i, NumSamples );

		float4 L = float4(0,0,0,0);
		
		#ifdef ANTONOV_SPHERE
			L = ImportanceSampleSphereUniform(Xi,N);
		#endif
		#ifdef ANTONOV_HEMISPHERE
			L = ImportanceSampleHemisphereUniform(Xi,N);
		#endif
		#ifdef ANTONOV_COSINE
			L = ImportanceSampleHemisphereCosine(Xi,N);
		#endif

		float NoL = saturate(dot(N, L));

		if( NoL > 0 )
		{
			//SampleColor += DecodeRGBMLinear(texCUBElod(_DiffCubeIBL, float4(L.xyz,calcLOD(_diffuseSize, L.w, NumSamples)))).rgb * NoL;
			SampleColor += texCUBElod(_DiffCubeIBL, float4(L.xyz,calcLOD(_diffuseSize, L.w, NumSamples))) * NoL;
			TotalWeight += NoL;
		}
	}
	
	return DecodeRGBMLinear(SampleColor / TotalWeight);
}		

// Brian Karis, Epic Games "Real Shading in Unreal Engine 4"
float3 SpecularIBL( float Roughness, float3 R )
{
	float3 N = R;
	float3 V = R;
			 
	float4 SampleColor = 0;
	float TotalWeight = 0;
			 
	float m = Roughness;
	float m2 = m*m;
		      
	const int NumSamples = _specSamples;
	for( int i = 0; i < NumSamples; i++ )
	{
		float2 Xi = Hammersley( i, NumSamples );
		
		float4 H = float4(0,0,0,0);

		#ifdef ANTONOV_BLINN
			H = ImportanceSampleBlinn(Xi, m, N);
		#endif
		#ifdef ANTONOV_GGX
			H = ImportanceSampleGGX(Xi, m, N);
		#endif
		
		float3 L = 2 * dot( V, H ) * H - V;
			               
	 	float NoL = saturate( dot( N, L ) );
	               
		if( NoL > 0 )
		{
			//SampleColor += DecodeRGBMLinear(texCUBElod( _SpecCubeIBL, float4(L, calcLOD(_specularSize, H.w, NumSamples ) ) ) ).rgb * NoL;
			SampleColor += texCUBElod( _SpecCubeIBL, float4(L, calcLOD(_specularSize, H.w, NumSamples ) ) ) * NoL;
				                        
			TotalWeight += NoL;
		}  
	}
	
	return DecodeRGBMLinear(SampleColor / TotalWeight);
}
	
float3 ApproximateSpecularIBL( float3 SpecularColor , float Roughness, float3 N, float3 V, float4 worldPos )
{
	float NoV = saturate( dot( N, V ) );

	float3 R = 2 * dot( V, N ) * N - V;

	float attenuation = 1;

	#ifdef ANTONOV_SPHERE_PROJECTION
		float3 probePos = _cubemapPos - worldPos;
		
		/*
		// http://http.developer.nvidia.com/GPUGems/gpugems_ch19.html
		float b = -2.0 * dot(R, probePos);
		float c = dot(probePos, probePos) - 1;
 		float discrim = b * b - 4.0 * c;
 		bool hasIntersects = false;
 		 if (discrim > 0) 
 		 {
    		// pick a small error value very close to zero as "epsilon"
    		hasIntersects = ((abs(sqrt(discrim) - b) / 2.0) > 0.00001);
 		 }
 		 if (hasIntersects) 
 		 {
    		// determine where on the unit sphere reflVect intersects
    		R = _cubemapScale * R - probePos;
  		}
		*/
		
		float b = dot(R, probePos);

		float c = dot(probePos, probePos);
		float d = c - b * b;
		float q  = b + sqrt( sqr(_cubemapScale) - d );

		R = worldPos + R * q - _cubemapPos ;

		//R =  (1 / _cubemapScale) * probePos + R; 	// Lagarde 2012, "Image-based Lighting approaches and parallax-corrected cubemap"	

		#ifdef ANTONOV_CUBEMAP_ATTEN
			float attenRadius = _attenSphereRadius;
			float attenInnerRadius = attenRadius-2.0f;
		
			attenuation =  1 - saturate(( sqrt( c ) - attenInnerRadius ) / ( attenRadius - attenInnerRadius ) );
		#endif
	#elif ANTONOV_BOX_PROJECTION
		// Lagarde 2012, "Image-based Lighting approaches and parallax-corrected cubemap"
		float3 rayLocalSpace = mul( _WorldToCube, float4(R,1));
		float3 positionLocalSpace = mul( _WorldToCubeInverse, worldPos);

		float3 cubemapBoxSize = _cubemapBoxSize/2.0f;
		
		float3 boxSize = float3(cubemapBoxSize);
		float3 firstPlaneIntersect  = (boxSize - positionLocalSpace) / rayLocalSpace;
		float3 secondPlaneIntersect = (-boxSize - positionLocalSpace) / rayLocalSpace;
		float3 furthestPlane = max(firstPlaneIntersect, secondPlaneIntersect);
		float distance = min(furthestPlane.x, min(furthestPlane.y, furthestPlane.z));

		R = positionLocalSpace + R * distance;
		
		#ifdef ANTONOV_CUBEMAP_ATTEN
			float3 probePos = ( worldPos - _cubemapPos);
			probePos = abs(probePos);
			
			float3 attenBoxSize = _attenBoxSize/2.0f;
			float3 attenInnerBoxSize = attenBoxSize-4.0f/2.0f;
			
			attenuation = min(min( attenBoxSize.x - probePos.x , attenBoxSize.y - probePos.y ),  attenBoxSize.z - probePos.z );
			attenuation /= min( min( attenBoxSize.x - attenInnerBoxSize.x , attenBoxSize.y - attenInnerBoxSize.y ), attenBoxSize.z - attenInnerBoxSize.z );
			attenuation = saturate( attenuation );
		#endif
	#endif

	float lod =_lodSpecCubeIBL;
	
	#ifdef SHADER_API_D3D9
		R = fix_cube_lookup(R,Roughness,lod);
	#endif
	
	float3 prefilteredColor = DecodeRGBMLinear(texCUBElod(_SpecCubeIBL,float4(R,Roughness * lod))) * attenuation;
	//float3 prefilteredColor = texCUBElod(_SpecCubeIBL,float4(R,Roughness * lod)) * attenuation;
	//float3 prefilteredColor = PrefilterEnvMap( Roughness, R ) * attenuation;

	float3 F = 0;
		
	
	#ifdef ANTONOV_FRESNEL_GGX
		F =  F_LazarovApprox( SpecularColor,Roughness, NoV );
	#endif			
	#ifdef ANTONOV_FRESNEL_BLINN
		F =  F_LagardeSchlick( SpecularColor,Roughness, NoV );
	#endif
	

	//return prefilteredColor * F;
	
	float2 F_G = tex2D(_ENV_LUT, float2(NoV, Roughness));
	return prefilteredColor * ( SpecularColor * F_G.x + F_G.y );
}

float3 ApproximateDiffuseIBL(float3 N)
{
float attenuation = 1;

/*
	#ifdef ANTONOV_SPHERE_PROJECTION
	float3 probePos = _cubemapPos - worldPos;
		
	float b = dot(N, probePos);

	float c = dot(probePos, probePos);
	float d = c - b * b;
	float q  = b + sqrt( sqr(_cubemapScale) - d );

	N = worldPos + N * q - _cubemapPos ;
	
		#ifdef ANTONOV_CUBEMAP_ATTEN
			float attenRadius = _attenSphereRadius;
			float attenInnerRadius = attenRadius-2.0f;
		
			attenuation =  1 - saturate(( sqrt( c ) - attenInnerRadius ) / ( attenRadius - attenInnerRadius ) );
		#endif
	
	#endif
*/

	float3 PrefilteredColor = DecodeRGBMLinear(texCUBE(_DiffCubeIBL,N)) * attenuation;
	//float3 PrefilteredColor = texCUBE(_DiffCubeIBL,N) * attenuation;
	
	return PrefilteredColor;
}


#endif

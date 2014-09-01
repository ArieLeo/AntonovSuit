#ifndef ANTONOV_SUIT_CONVOLVE_FRAG
#define ANTONOV_SUIT_CONVOLVE_FRAG

// Brian Karis, Epic Games "Real Shading in Unreal Engine 4"
float3 DiffuseIBL(float3 R, int NumSamples )
{
	float3 N = R;
	float3 V = R;
	float3 SampleColor = 0;
	float TotalWeight = 0;
	
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
			SampleColor += DecodeRGBMLinear(texCUBElod(_DiffCubeIBL, float4(L.xyz,calcLOD(_diffuseSize, L.w, NumSamples)))) * NoL;
			TotalWeight += NoL;
		}
	}
	return SampleColor / TotalWeight;
}

// Brian Karis, Epic Games "Real Shading in Unreal Engine 4"
float3 SpecularIBL( float Roughness, float3 R, int NumSamples )
{
	float3 N = R;
	float3 V = R;
			 
	float3 SampleColor = 0;
	float TotalWeight = 0;
			 
	float m = Roughness;
	float m2 = m*m;

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
			SampleColor += DecodeRGBMLinear(texCUBElod(_SpecCubeIBL, float4(L, calcLOD(_specularSize, H.w, NumSamples)))) * NoL;
				                        
			TotalWeight += NoL;
		}  
	}
	
	return SampleColor / TotalWeight;
}

struct data 
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};
			
struct v2f 
{
	float4	vertex 		: POSITION;
	float3	texcoord	: TEXCOORD3;
};
			
v2f vert(appdata_tan v)
{
	v2f o;
	o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
	o.texcoord = v.texcoord;
	return o;
}
			
float4 frag( v2f i ) : COLOR
{
	float3 normal = normalize(i.texcoord);

	float4 frag = float4(0,0,0,1);
			
			
	#ifdef ANTONOV_64_SAMPLES && ANTONOV_IMPORTANCE_DIFFUSE
		frag.rgb += DiffuseIBL(normal, 64);
	#endif
	
	#ifdef ANTONOV_128_SAMPLES && ANTONOV_IMPORTANCE_DIFFUSE
		frag.rgb += DiffuseIBL(normal, 128);
	#endif
	
	#ifdef ANTONOV_256_SAMPLES && ANTONOV_IMPORTANCE_DIFFUSE
		frag.rgb += DiffuseIBL(normal, 256);
	#endif
	
	#ifdef ANTONOV_64_SAMPLES && ANTONOV_IMPORTANCE_SPECULAR 
		frag.rgb += SpecularIBL(_Shininess, normal, 64);
	#endif
	
	#ifdef ANTONOV_128_SAMPLES && ANTONOV_IMPORTANCE_SPECULAR
		frag.rgb += SpecularIBL(_Shininess, normal, 128);
	#endif
	
	#ifdef ANTONOV_256_SAMPLES && ANTONOV_IMPORTANCE_SPECULAR
		frag.rgb += SpecularIBL(_Shininess, normal, 256);
	#endif
				
	return HDRtoRGBM(frag);
}

#endif			
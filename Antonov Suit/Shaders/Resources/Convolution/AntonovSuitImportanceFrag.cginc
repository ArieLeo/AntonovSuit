#ifndef ANTONOV_SUIT_CONVOLVE_FRAG
#define ANTONOV_SUIT_CONVOLVE_FRAG

// we can get away with 32 samples with a 256x256 cubemap
inline float calcLOD(int size, float pdf, int NumSamples)
{
	float preCalcLod = log2( (size*size) / NumSamples);
	return 0.5 * preCalcLod - 0.5 * log2( pdf );
}

// Brian Karis, Epic Games "Real Shading in Unreal Engine 4"
float3 DiffuseIBL(float3 R, int NumSamples, int cubeSize )
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
			SampleColor += DecodeRGBMLinear(texCUBElod(_DiffCubeIBL, float4(L.xyz,calcLOD(cubeSize, L.w, NumSamples)))) * NoL;
			TotalWeight += NoL;
		}
	}
	return SampleColor / TotalWeight;
}

// Brian Karis, Epic Games "Real Shading in Unreal Engine 4"
float3 SpecularIBL( float Roughness, float3 R, uint NumSamples, uint cubeSize )
{
	float3 N = R;
	float3 V = R;
			 
	float3 SampleColor = 0;
	float TotalWeight = 0;
			 
	float m = Roughness;
	float m2 = m*m;
	
	for( uint i = 0; i < NumSamples; i++ )
	{
		float2 Xi = Hammersley( i, NumSamples ) + 1.e-6f;
		
		float4 H = float4(0,0,0,0);

		#ifdef ANTONOV_BLINN
			H += ImportanceSampleBlinn(Xi, m, N);
		#endif
		#ifdef ANTONOV_GGX
			H += ImportanceSampleGGX(Xi, m, N);
		#endif
		
		float3 L = 2 * dot( V, H ) * H - V;
			               
	 	float NoL = saturate( dot( N, L ) );
	 	float NoH = saturate( dot( N, H ) );
		float VoH = saturate( dot( V, H ) );
		float NoV = saturate( dot( N, V ) );
    
		if( NoL > 0 )
		{          
		
			float D = m2 / (PI * pow((NoH*NoH) * (m2 - 1.0f) + 1.0f, 2.0f));
			float pm = D * NoV;
			float pdf = pm / (4.0f * VoH);
			                         
			SampleColor += DecodeRGBMLinear(texCUBElod(_SpecCubeIBL, float4(L, calcLOD(cubeSize, pdf, NumSamples)))) * NoL;
				                        
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
			
	#ifdef ANTONOV_IMPORTANCE_DIFFUSE	
		frag.rgb += DiffuseIBL(normal, _diffSamples, _diffuseSize);
	#endif
	
	#ifdef ANTONOV_IMPORTANCE_SPECULAR 
		frag.rgb += SpecularIBL(_Shininess, normal, _specSamples, _specularSize);
	#endif
	
	return HDRtoRGBM(frag);
}

#endif			
// Created by Charles Greivelding
			
			
			inline void DecodeDirLightmap(half3 normal, float4 colorLM, float4 scaleLM, out half3 lightColor, out half3 lightDir)
			{
				UNITY_DIRBASIS
				half3 scalePerBasisVector;

				lightColor = DirLightmapDiffuse (unity_DirBasis, colorLM, scaleLM, normal,true,scalePerBasisVector);
				lightDir = normalize (scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2]);
			}
			
			struct v2f 
			{
			    float4	pos 		: POSITION;
			    float3	lightDir	: TEXCOORD0;
			    float3	normal		: TEXCOORD1;
			    float4	worldPos	: TEXCOORD2;
			    float2	uv			: TEXCOORD3;
			    float3	lightmap	: TEXCOORD4;
			    LIGHTING_COORDS(5,6)
				float3 	TtoW0		: TEXCOORD7;
				float3 	TtoW1		: TEXCOORD8;
				float3 	TtoW2		: TEXCOORD9;
			};
			
			v2f vert(appdata_full v)
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
				#ifdef LIGHTMAP_ON
					o.lightmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					o.lightmap.z = 0;
				#endif
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
				half3 white = half3(1.0,1.0,1.0);
				half3 black = half3(0.0,0.0,0.0);
			
			    //float2 screenCoord = i.screenPos.xy / i.screenPos.w;
			    
			    //ALPHA
				half alpha = tex2D(_RGBTex, uv_metallic).a;
				
				#ifdef ANTONOV_WORKFLOW_SPECULAR
					alpha = tex2D(_RGBTex, uv_metallic).r;
				#endif
					
			    
			    //METALLIC
				half metallic = tex2D(_RGBTex, uv_metallic).x;
			    
			    //OCCLUSION
				half occlusion = half(1.0f);
			
				occlusion = tex2D( _RGBTex, uv_occlusion ).z;
				occlusion = lerp(white,occlusion,_occlusionAmount);
			
			    float4 worldPos = i.worldPos;
			    
			    half3 viewDir = normalize( i.worldPos - _WorldSpaceCameraPos );
			  
			    half3 lightColor = _LightColor0.rgb * 2;
				half3 lightDir = normalize(i.lightDir);

				half atten = LIGHT_ATTENUATION(i);

			    //BASE COLOR
				half4 baseColor = tex2D(_MainTex, uv_base);
				baseColor.rgb *= _Color.rgb;
				
				//ROUGHNESS
				half roughness = sqrt(tex2D(_RGBTex, uv_metallic).y);
				roughness = roughness*roughness;
				roughness *= _Shininess;
				
				//CAVITY
				#ifdef ANTONOV_SKIN
					float cavity =  tex2D( _RGBSkinTex, uv_base ).x;
					cavity = lerp(1.0f, cavity, _cavityAmount);
				#endif
				
				//NORMAL
				float3 normal = UnpackNormal(tex2D(_BumpMap, uv_bump));
				
				#ifdef ANTONOV_SKIN
					float3 vertexNormal = float3(0,0,1); // Z-Up Vertex tangent space normal

					float3 microNormal = UnpackNormal(tex2D(_BumpMicroTex,uv_bump*_microScale));
					microNormal = lerp(vertexNormal,microNormal,_microBumpAmount);
											
					normal.xy += microNormal.xy;
				#endif
				
				float3 worldNormal = float3(0,0,0);
				worldNormal.x = dot(i.TtoW0, normal);
				worldNormal.y = dot(i.TtoW1, normal);
				worldNormal.z = dot(i.TtoW2, normal);
			
				worldNormal = normalize(worldNormal);
				
				//VERTEX NORMAL
				#ifdef ANTONOV_SKIN
					float3 worldVertexNormal = float3(0,0,0);
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
				#endif
				
				//LIGHTMAP
				half3 lightmap = 1;
				half3 attenuatedLight = lightColor * atten;
				#ifdef LIGHTMAP_ON
					float4 lightmapColor = tex2D(unity_Lightmap, i.lightmap.xy);
					#ifdef DIRLIGHTMAP_OFF
						lightmap = DecodeLightmap(lightmapColor);
						attenuatedLight = lightmap;
					#endif	
					#ifdef DIRLIGHTMAP_ON
						float4 lightmapScale = tex2D(unity_LightmapInd, i.lightmap.xy);

						half3 lightDirTangent;
						DecodeDirLightmap (normal, lightmapColor, lightmapScale, lightColor, lightDirTangent); // We are in Tangent here
						// Back to World
						lightDir.x = dot(i.TtoW0,  lightDirTangent);
						lightDir.y = dot(i.TtoW1,  lightDirTangent);
						lightDir.z = dot(i.TtoW2,  lightDirTangent);

						lightDir = normalize(lightDir);		
						attenuatedLight = max(min(lightColor, atten * lightmapColor.rgb), atten * lightColor);				
					#endif
					
				#endif
				
				//VECTORS
				#ifdef ANTONOV_SKIN
					float3 h = -viewDir + lightDir;	
					half3 halfVector = normalize(h);
					half HalfLambert = saturate( dot( worldNormal, lightDir ) * 0.5 + 0.5 );
				#else
					half3 halfVector = normalize(-viewDir+lightDir);
				#endif
				
				half NdotL = saturate( dot( worldNormal, lightDir ) );
				half NdotV = saturate( dot( worldNormal, -viewDir ) );
				half NdotH = saturate( dot( worldNormal, halfVector ) );
				half LdotH = saturate( dot( lightDir, halfVector ) );
				half VdotH = saturate( dot( -viewDir, halfVector ) );
				
					
				//SHADOWS
				#ifdef ANTONOV_SKIN
					float3 skinShadow = tex2D( _SKIN_LUT,float2(atten,.9999));
				#endif
				
				//VIEW DEPENDENT ROUGHNESS				
				roughness = lerp( 0.0, roughness, NdotV) * _viewDpdtRoughness + roughness * ( 1 - _viewDpdtRoughness );
				
				roughness =  max(roughness,0.01);
				
				//ROUGHNESS AA
				float roughnessAA = roughness;
				
				#ifdef ANTONOV_TOKSVIG
					float normalMapLen = length(tex2D(_BumpMap, uv_bump)*2-1);
					float s = RoughnessToSpecPower(roughness);
					
					float ft = normalMapLen / lerp(s, 1.0f, normalMapLen);
	                ft = max(ft, 0.01f);
	                
	                roughnessAA = SpecPowerToRoughness(ft * s) * _toksvigFactor + roughness * ( 1 - _toksvigFactor );
                #endif
				
				float4 frag = float4(0,0,0, alpha * _Color.a );

				//DIFFUSE
				half4 diffuse = baseColor;
				
				#ifdef ANTONOV_METALLIC
					diffuse = half4(0,0,0,1); //No diffuse color as it is pure metal
				#endif
				
				#ifdef ANTONOV_METALLIC_DIELECTRIC
					half4 diffuseMetallic = half4(0.0,0.0,0.0,1);
					diffuse = lerp(diffuse,diffuseMetallic,metallic);
				#endif

				half3 diffuseDirect = 0;	
		
				#ifdef ANTONOV_METALLIC
					diffuseDirect = 0; // Make sure we don't have any diffuse light with metal
				#endif
		
				#ifdef ANTONOV_DIFFUSE_LAMBERT
					diffuseDirect = NdotL;
				#endif
					
				#ifdef ANTONOV_DIFFUSE_BURLEY
					diffuseDirect = Burley(NdotL, NdotV, VdotH, roughness );
				#endif
				  
				#ifdef ANTONOV_SKIN
					diffuseDirect = PennerSkin( float3( _tuneSkinCoeffX,_tuneSkinCoeffY,_tuneSkinCoeffZ ), worldNormal,lightDir, blurredNormal, curvature, _SKIN_LUT, atten );
				#endif
				
				#ifdef ANTONOV_SKIN
					diffuseDirect *=  lightColor * skinShadow;
				#else				
					diffuseDirect *= attenuatedLight;	
				#endif	
				
				//SPECULAR	
				half4 specular = half4(0,0,0,0);
				
				#ifdef ANTONOV_WORKFLOW_SPECULAR
					specular = tex2D(_SpecTex, uv_spec);
					specular.rgb *= _SpecColor.rgb;
				#endif
					
				#ifdef ANTONOV_WORKFLOW_METALLIC
			   		specular = baseColor;
				#endif
				
				#ifdef ANTONOV_DIELECTRIC
					specular =  half4(0.04,0.04,0.04,1);
				#endif
				
				#ifdef ANTONOV_SKIN
					specular = half4(0.028,0.028,0.028,1) * cavity * microCavity;
				#endif

				#ifdef ANTONOV_METALLIC_DIELECTRIC	
					half4 specularDielectric = half4(0.04,0.04,0.04,1);
					specular = lerp(specularDielectric,specular,metallic);
				#endif

				#ifdef ANTONOV_SKIN
					half D = D_Beckmann(roughness, NdotH);
					half G = 1;
				#else
					half D = D_GGX(roughnessAA, NdotH);
					half G = G_GGX(roughnessAA, NdotL, NdotV);
				#endif

				half3 F = F_Schlick( specular, LdotH );
				
				#ifdef LIGHTMAP_ON
					#ifdef ANTONOV_DIELECTRIC
						attenuatedLight = Luminance(attenuatedLight);
					#endif
					#ifdef ANTONOV_METALLIC_DIELECTRIC
						attenuatedLight = lerp(Luminance(attenuatedLight), attenuatedLight, metallic);
					#endif	
				#endif
				
				#ifdef ANTONOV_SKIN
					half3 specularDirect = max( D * F / dot( h, h ), 0 ) * NdotL * attenuatedLight;
				#else
					half3 specularDirect = D * G * F * NdotL * attenuatedLight;
				#endif		

				//SPECULAR IBL
				half3 specularIBL = ApproximateSpecularIBL( specular.rgb, roughness, worldNormal, -viewDir, i.worldPos, i.normal ) * _exposureIBL.x;
				//half horyzon = saturate( 1 + _horyzonOcclusion * specularOcclusion(i.normal, -viewDir, occlusion) );
				//specularIBL *= specularOcclusion(i.normal, -viewDir, occlusion);
		
				//DIFFUSE IBL
				#ifdef ANTONOV_SKIN
					half3 diffuseIBL = diffuseSkinIBL(float3(_tuneSkinCoeffX, _tuneSkinCoeffY, _tuneSkinCoeffZ), ApproximateDiffuseIBL(worldNormal).rgb, ApproximateDiffuseIBL(blurredNormal).rgb) * _exposureIBL.y;
				#else
					half3 diffuseIBL = ApproximateDiffuseIBL(worldNormal) * _exposureIBL.y;
				#endif
				
				//AMBIENT
				half3 ambient = UNITY_LIGHTMODEL_AMBIENT;
				//half3 topLighting = saturate( dot( worldNormal, float3(0,1,0) ) * 0.5 + 0.5 );
				//half3 ambientIBL = DecodeRGBMLinear(texCUBE(_AmbCubeIBL,worldNormal));
				//half3 ambient = lerp(_groundColor, _skyColor + ambientIBL,topLighting);
			
				half3 ambientProbe = ShadeSH9(float4(worldNormal,1));
			
											
				#ifdef LIGHTMAP_ON
					// We normalize the cubemap with lightmap here.
					diffuseIBL *= attenuatedLight;
					specularIBL *= attenuatedLight;
				#endif

				#ifdef ANTONOV_METALLIC
					diffuseIBL = half3(0,0,0);
					ambient = half3(0,0,0);
				#endif
				
				half3 diffuseOcclusion = coloredOcclusion(diffuse, occlusion);
				
				#ifdef ANTONOV_WORKFLOW_SPECULAR
					diffuse.rgb *= saturate(1.0f - specular); // We balance the diffuse with specular intensity, The Order 1886
				#endif
				
				#ifdef ANTONOV_FWDBASE
					frag.rgb = ( diffuseDirect + diffuseIBL + ambient ) * diffuse * occlusion;

					frag.rgb += ( specularDirect + specularIBL ) * occlusion;
				#else	
					frag.rgb = diffuseDirect * diffuse * occlusion;
					
					frag.rgb += specularDirect * occlusion;
				#endif
		
				#ifdef ANTONOV_ILLUM
				//ILLUM
					half3 illum = tex2D( _Illum, uv_base );
					half3 illumColor = half3( _illumColorR, _illumColorG, _illumColorB );
					illum = lerp( half3( 0.0, 0.0,0.0 ), illum * illumColor, _illumStrength );
					
					frag.rgb += illum;
				#endif
				
				return frag;
			}
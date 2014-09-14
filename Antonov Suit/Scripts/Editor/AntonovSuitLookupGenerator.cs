// Lookup generator
// Created by Charles Greivelding

using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
using System.Collections.Generic;
using System.IO;
#endif
 
class AntonovSuitLookupGenerator : ScriptableWizard 
{

	public string nameTex = "MyLookUp_LUT";

	public enum size_Enum
	{
		_64px = 64, _128px = 128, _256px = 256, _512px = 512
	};

	public size_Enum size = size_Enum._256px;

	private int samples = 256;

	public enum D_Enum
	{
		D_GGX,
		D_Blinn
	};
	
	public D_Enum D_Model = D_Enum.D_GGX;

	public enum G_Enum
	{
		G_Schlick,
		G_Smith
	};

	public G_Enum G_Model = G_Enum.G_Schlick;

    [MenuItem ("Antonov Suit/Lookup Generator")]
    static void CreateWizard () 
	{
		ScriptableWizard.DisplayWizard<AntonovSuitLookupGenerator>("BRDF Lookup Generator", "Compute");
    }

	float RadicalInverse(int n, int b)
	{
		float bits = 0.0f;
		float invBase = 1.0f / b, invBi = invBase;
		while (n > 0) 
		{
			int d_i = (n % b);
			bits += d_i * invBi;
			n /= b;
			invBi *= invBase;
		}
		return (bits);
	}

	Vector2 Hammersley(int i, int N)
	{
		return new Vector2( (float)i * ( 1.0f / (float)N ), RadicalInverse(i,3) );
	}

	Vector2 Hammersley2D(int i, int N) 
	{
		return new Vector2((float)i/(float)N, RadicalInverse(i,3));
	}

	Vector3 ImportanceSampleGGX(Vector2 Xi, float Roughness)
	{

		float a = Roughness;

		float phi = 2 * Mathf.PI * Xi.x;
		float cosTheta = Mathf.Sqrt( (1 - Xi.y) / ( 1 + (a*a - 1) * Xi.y) );
		float sinTheta = Mathf.Sqrt(1 - cosTheta * cosTheta);

		Vector3 H = new Vector3(sinTheta * Mathf.Cos(phi), sinTheta * Mathf.Sin(phi), cosTheta);

		return H;
	}

	Vector3 ImportanceSampleBlinn( Vector2 Xi, float Roughness )
	{
		float m = Roughness * Roughness;

		float n = 2 / (m*m) - 2;

		float phi = 2 * Mathf.PI * Xi.x;

		float CosTheta = Mathf.Pow( Mathf.Max(Xi.y, 0.0001f), 1 / (n + 1) );
		float SinTheta = Mathf.Sqrt( 1 - CosTheta * CosTheta );
		
		Vector3 H = new Vector3(SinTheta * Mathf.Cos( phi ), SinTheta * Mathf.Sin( phi ), CosTheta);
		
		return H;
	}
	
	float G_Schlick(float Roughness, float NdotV, float NdotL)
	{

		float m = Roughness;

		return (NdotV * NdotL) / ( (NdotV * (1 - m) + m) * (NdotL * (1 - m) + m) );
	}

	float G_Smith( float Roughness, float NoV, float NoL )
	{
		float m = Roughness;
		
		float G_SmithV = NoV + Mathf.Sqrt( NoV * (NoV - NoV * m) + m );
		float G_SmithL = NoL + Mathf.Sqrt( NoL * (NoL - NoL * m) + m );

		return  1 / G_SmithV * G_SmithL;
	}

	Vector2 IntegrateBRDF(float NoV, float roughness)
	{

		Vector3 V = new Vector3(Mathf.Sqrt( 1.0f - NoV * NoV ), 0, NoV);

		float m = roughness*roughness;

		float A = 0;
		float B = 0;

		int numSamples = samples;
		for( int i = 0; i < numSamples; i++ )
		{
			Vector2 Xi = Hammersley( i, numSamples );

			Vector3 H = new Vector3(0,0,0);

			if( D_Model == D_Enum.D_GGX )
			{
				H = ImportanceSampleGGX( Xi, m);
			}
			if( D_Model == D_Enum.D_Blinn )
			{
				H = ImportanceSampleBlinn( Xi, m);
			}

			Vector3 L = 2 * Vector3.Dot( V, H ) * H - V;

			float NoL = L.z;
			float NoH = H.z;
			float VoH = Vector3.Dot( V, H );

			if( NoL > 0 )
			{
				if( G_Model == G_Enum.G_Schlick )
				{
					float G = G_Schlick( m, NoV, NoL );
					float G_Vis = G * VoH / (NoH * NoV);
					float Fc = Mathf.Pow( 1.0f - VoH, 5.0f );
					A += (1.0f - Fc) * G_Vis;
					B += Fc * G_Vis;
				}
				if( G_Model == G_Enum.G_Smith )
				{
					float G = G_Smith( m, NoV, NoL );
					float Fc = Mathf.Pow( 1.0f - VoH, 5.0f );
					A += (1.0f - Fc) * G;
					B += Fc * G;
				}

			}

		}

		return new Vector2(A, B) / numSamples;
	}

    void OnWizardCreate () 
	{
		string extension = ".png";
		string path = Application.dataPath + "/Antonov Suit/Textures/Shaders/" + nameTex + extension;

		int width = (int)size;
		int height = (int)size;

		Texture2D texture = new Texture2D(width, height, TextureFormat.ARGB32, false);

		try 
		{
			for (int j = 0; j < height; ++j) 
			{
				for (int i = 0; i < width; ++i) 
				{
					Vector2 FG = IntegrateBRDF( (i+1)/(float) width, (j+1)/(float)height);
					texture.SetPixel(i, j, new Color( FG.x,FG.y,0));
				}


				
				float progress = (float)j / (float)height;
				bool canceled = EditorUtility.DisplayCancelableProgressBar("Processing Computation", "", progress);
				if (canceled)
					return;					
			}
			texture.wrapMode = TextureWrapMode.Clamp;

			texture.Apply();

			byte[] bytes = texture.EncodeToPNG();

			File.WriteAllBytes(path, bytes);
		} 
		finally 
		{
			DestroyImmediate(texture);
			EditorUtility.ClearProgressBar();
		}
    }

}
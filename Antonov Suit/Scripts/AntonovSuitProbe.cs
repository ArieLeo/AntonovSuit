// Cubemap capture script based on http://alastaira.wordpress.com/2013/11/12/oooh-shiny-fun-with-cube-mapping/ and on LUX http://forum.unity3d.com/threads/lux-an-open-source-physically-based-shading-framework.235027/
// Created by Charles Greivelding

using UnityEngine;
using System.Collections;

#if UNITY_EDITOR
using UnityEditor;
#endif
using System.Collections.Generic;
using System.IO;


[ExecuteInEditMode]
public class AntonovSuitProbe : MonoBehaviour 
{
	private Shader HDRtoRGBM;

	public string cubemapFolder = "Assets/Antonov Suit/Textures/Cubemaps/";
	//public string sceneName;
	public string cubemapName = "Cube";

	//public int diffuseSize = 64;
	//public int specularSize = 256;

	[System.Serializable]
	public enum facesSize
	{
		_64, 
		_128, 
		_256, 
		_512,
	};

	public facesSize diffuseSize = facesSize._64;

	public facesSize specularSize = facesSize._256;

	[System.Serializable]
	public enum qualitySamples
	{
		Low,
		Medium,
		High
	};

	public qualitySamples diffuseSamples = qualitySamples.Low;

	public qualitySamples specularSamples = qualitySamples.Low;

	public int smoothEdge = 4;
	//public float edgeScale = 0.1f;
	
	private Material[] m_materials;

	//public int diffuseSamples = 32;
	//public int specularSamples = 64;

	public GameObject[] Meshes;

	private Cubemap emptyCube;
	public Cubemap diffuseCube;
	public Cubemap specularCube;

	private Camera cubeCamera; 
	//public Mesh outsideCubeMesh;

	//Parallax
	//public GameObject[] probeObjects;

	[System.Serializable]
	public enum ProjectionType
	{	
		InfiniteProjection,
		SphereProjection,
		BoxProjection,
	};

	public ProjectionType typeOfProjection = ProjectionType.InfiniteProjection;

	private Matrix4x4 probeMatrix;
	
	public bool useAtten;

	public float probeRadius;
	public float attenSphereRadius;

	//Custom exposure control
	public float diffuseExposure = 1;
	public float specularExposure = 1;
	
	public Vector3 probeBoxSize;
	public Vector3 attenBoxSize;

	private Vector3 cubePos;

	//Importance sampled material for skybox
	private Material convolveDiffuseSkybox;
	private Material convolveSpecularSkybox;

	public int specularExponent = 1;

	//PREVIEW
	public GameObject previewProbe;
	public Material previewMaterial;

	//Always true
	private bool RGBM = true;

	public bool bakeDirectAndIBL = false;

	[System.Serializable]
	public enum radianceEnum
	{
		GGX,
		BlinnPhong
	};

	public radianceEnum radianceModel = radianceEnum.GGX;

	[System.Serializable]
	public enum irradianceEnum
	{
		SphereUniform,
		HemisphereUniform,
		HemisphereCosine,
	};
	
	public irradianceEnum irradianceModel = irradianceEnum.SphereUniform;

	public bool goConvolveIrradiance = false;
	public bool goConvolveRadiance = false;

	public bool goBake = false;
	public bool done = false;

	#if UNITY_EDITOR
	void SetLinearSpace(ref SerializedObject obj, bool linear)
	{
		if (obj == null) return;
		
		SerializedProperty prop = obj.FindProperty("m_ColorSpace");
		if (prop != null)
		{
			prop.intValue = linear ? (int)ColorSpace.Gamma : (int)ColorSpace.Linear;
			obj.ApplyModifiedProperties();
		}
	}

	public string GetOutPutPath(Cubemap cubemap, bool diffuse)
	{
		/*
		if (EditorApplication.currentScene != "")
		{
			List<string> pathTemp = new List<string>(EditorApplication.currentScene.Split(char.Parse("/")));
			pathTemp[pathTemp.Count - 1] = pathTemp[pathTemp.Count - 1].Substring(0, pathTemp[pathTemp.Count - 1].Length - 6);
			sceneName = string.Join("/", pathTemp.ToArray()) + "/";
		}
		*/
		if(diffuse)
		{
			cubemap.name = cubemapFolder + cubemapName + "@ " + this.gameObject.transform.position + "_DIFF.cubemap";
		}
		else
		{
			cubemap.name = cubemapFolder + cubemapName + "@ " + this.gameObject.transform.position + "_SPEC.cubemap";
		}
		return cubemap.name;
	}

	#endif

	int CubeSizeSetup(bool isDiffuse)
	{
		
		int result= 0;
		
		if( isDiffuse == true )
		{
			if(diffuseSize == facesSize._64)
			{
				result = 64;
			}
			if(diffuseSize == facesSize._128)
			{
				result  = 128;
			}
			if(diffuseSize == facesSize._256)
			{
				result  = 256;
			}
			if(diffuseSize == facesSize._512)
			{
				result  = 512;
			}
		}
		else
		{
			if(specularSize == facesSize._64)
			{
				result = 64;
			}
			if(specularSize == facesSize._128)
			{
				result  = 128;
			}
			if(specularSize == facesSize._256)
			{
				result  = 256;
			}
			if(specularSize == facesSize._512)
			{
				result  = 512;
			}
		}
		return result;
	}

	// Resize a Texture2D
	// http://docs-jp.unity3d.com/Documentation/ScriptReference/Texture2D.GetPixelBilinear.html
	Texture2D Resize(Texture2D sourceTex, int Width, int Height, bool flipY) 
	{
		Texture2D destTex = new Texture2D(Width, Height, sourceTex.format, false);
		Color[] destPix = new Color[Width * Height];
		int y = 0;
		while (y < Height) 
		{
			int x = 0;
			while (x < Width) 
			{
				float xFrac = x * 1.0F / (Width );
				float yFrac = y * 1.0F / (Height);
				if(flipY == true)
					yFrac = (1 - y - 2) * 1.0F / (Height);
				destPix[y * Width + x] = sourceTex.GetPixelBilinear(xFrac, yFrac);
				x++;
			}
			y++;
		}
		destTex.SetPixels(destPix);
		destTex.Apply();
		return destTex;
	}
	
	IEnumerator Capture(Cubemap cubemap,CubemapFace face,Camera cam)
	{
		var width = Screen.width;
		var height = Screen.height;

		Texture2D tex = new Texture2D(height, height, TextureFormat.ARGB32, false);
		int cubeSize = cubemap.height;
		
		cam.transform.localRotation = Rotation(face);
		
		yield return new WaitForEndOfFrame();

		tex.ReadPixels(new Rect((width-height)/2, 0, height, height), 0, 0);
		tex.Apply();
		tex = Resize(tex, cubeSize,cubeSize,false);

		Color cubeCol;
		for (int y = 0; y < cubeSize; y++)
		{
			for (int x = 0; x < cubeSize; x++)
			{

				cubeCol = tex.GetPixel(cubeSize + x, (cubeSize - 1) - y);

				cubemap.SetPixel(face, x, y, cubeCol);

			}
		}

		cubemap.Apply();

		DestroyImmediate(tex);
	}

	Quaternion RotationInv(CubemapFace face)
	{
		Quaternion result;
		switch(face)
		{
		case CubemapFace.PositiveX:
			result = Quaternion.Euler(0, 90, -180);
			break;
		case CubemapFace.NegativeX:
			result = Quaternion.Euler(0, -90, 180);
			break;
		case CubemapFace.PositiveY:
			result = Quaternion.Euler(-90, 0, 0);
			break;
		case CubemapFace.NegativeY:
			result = Quaternion.Euler(90, 0, 0);
			break;
		case CubemapFace.NegativeZ:
			result = Quaternion.Euler(-180, 0, 0);
			break;
		default:
			result = Quaternion.Euler(0, 0, -180);
			break;
		}
		return result;
	}

	IEnumerator CaptureImportanceSample(Cubemap cubemap,CubemapFace face,Camera cam, int mip)
	{



		var width = Screen.width;
		var height = Screen.height;
		Texture2D tex = new Texture2D(height, height, TextureFormat.ARGB32, false);

		cam.transform.localRotation = Rotation(face);
		
		yield return new WaitForEndOfFrame();
		
		tex.ReadPixels(new Rect((width-height)/2, 0, height, height), 0, 0);
		tex.Apply();

		int cubeSize = Mathf.Max(1, cubemap.width >> mip );
	
		tex = Resize(tex, cubeSize,cubeSize,true);

		Color[] tempCol = tex.GetPixels();

		cubemap.SetPixels(tempCol,face,mip);

		cubemap.Apply(false);

		DestroyImmediate(tex);
	}

	Quaternion Rotation(CubemapFace face)
	{
		Quaternion result;
		switch(face)
		{
		case CubemapFace.PositiveX:
			result = Quaternion.Euler(0, 90, 0);
			break;
		case CubemapFace.NegativeX:
			result = Quaternion.Euler(0, -90, 0);
			break;
		case CubemapFace.PositiveY:
			result = Quaternion.Euler(-90, 0, 0);
			break;
		case CubemapFace.NegativeY:
			result = Quaternion.Euler(90, 0, 0);
			break;
		case CubemapFace.NegativeZ:
			result = Quaternion.Euler(0, 180, 0);
			break;
		default:
			result = Quaternion.Euler(0, 0, 0);
			break;
		}
		return result;
	}

	// Use this for initialization
	void Start () 
	{
		if (previewProbe != null && previewProbe.GetComponent<MeshRenderer>())
		{
			previewProbe.GetComponent<MeshRenderer>().enabled = false;
		}
	}

	#if UNITY_EDITOR
	public void InitCreateCube()
	{
		EditorApplication.isPlaying = true;
		StartCoroutine(GoBake());  
	}

	public void InitConvolveIrradianceCube()
	{
		EditorApplication.isPlaying = true;
		StartCoroutine(GoConvolveIrradiance());  
	}
	public void InitConvolveRadianceCube()
	{
		EditorApplication.isPlaying = true;
		StartCoroutine(GoConvolveRadiance());  
	}

	IEnumerator GoBake()
	{
		StartCoroutine(Bake());
		goBake = true;
		yield return null;
	}
	IEnumerator GoConvolveIrradiance()
	{	
		StartCoroutine(ConvolveIrradiance());
		goConvolveIrradiance = true;
		yield return null;
	}
	IEnumerator GoConvolveRadiance()
	{	
		StartCoroutine(ConvolveRadiance());
		goConvolveRadiance = true;
		yield return null;
	}

	void OnEnable()
	{

		if (previewProbe == null)
		{
			previewProbe = GameObject.CreatePrimitive(PrimitiveType.Sphere);
			previewProbe.name = this.name + "_Debug";
			DestroyImmediate(previewProbe.GetComponent<SphereCollider>(), false);
		}

		previewMaterial = new Material( Shader.Find("Hidden/Antonov Suit/Probe" ));
		previewMaterial.hideFlags = HideFlags.HideAndDontSave;
		
		MeshRenderer targetRenderer = previewProbe.GetComponent<MeshRenderer>();
		targetRenderer.enabled = true;
		targetRenderer.material = previewMaterial;
		
		targetRenderer.castShadows = false;
		targetRenderer.receiveShadows = false;

		previewProbe.transform.position = transform.position;
		previewProbe.transform.localScale = transform.localScale * 0.5f;
		previewProbe.transform.parent = transform;
		previewProbe.hideFlags = HideFlags.HideInHierarchy;
	}

	void OnDisable()
	{

		DestroyImmediate(previewMaterial, true);
	}

	IEnumerator Bake()
	{
		
		if (goBake && EditorApplication.isPlaying)
		{

			CameraSetup(false);
			
			StartCoroutine(CreateCubeMap(true));
			StartCoroutine(CreateCubeMap(false));  
		}		
		
		Resources.UnloadUnusedAssets();
		AssetDatabase.Refresh();
		yield return new WaitForEndOfFrame();
		
	}

	void CameraSetup(bool convolve)
	{
		
		// Disable any renderers attached to this object which may get in the way of our camera
		if(renderer) 
		{
			renderer.enabled = false;
		}
		
		// Create a camera that will be used to render the faces
		GameObject go = new GameObject("CubemapCamera", typeof(Camera));
		
		cubeCamera = go.GetComponent<Camera>();
		
		// Place the camera on this object
		cubeCamera.transform.position = transform.position;
		
		// Initialise the rotation - this will be changed for each texture grab
		cubeCamera.transform.rotation = Quaternion.identity;

		/*
		if(convolve == false && SystemInfo.graphicsShaderLevel != 50)
		{
			CubeSizeSetup(false);
			cubeCamera.fieldOfView = 90 + 90f / (float)64 * 0.7f;
		}
		else
		{
			cubeCamera.fieldOfView = 90;
		}
		*/

		cubeCamera.fieldOfView = 90;

		// Ensure this camera renders above all others
		cubeCamera.depth = float.MaxValue;

		if( goConvolveIrradiance == true || goConvolveRadiance == true)
		{
			cubeCamera.clearFlags = CameraClearFlags.Skybox;
		
			//Show sky only, previous attempt were using a inverted sphere but using a skybox is much better
			cubeCamera.cullingMask = 0;
		}


			// HDR TO RGBM
			if(RGBM == true )
			{

					bool hasPro = UnityEditorInternal.InternalEditorUtility.HasPro();
					
					if( hasPro == true && convolve == false )
					{		
						cubeCamera.hdr = true;	
						go.AddComponent<HDRtoRGBM>();
					}
					if( hasPro == false && convolve == false )
					{
						cubeCamera.hdr = false;
						go.AddComponent<RGBM>();
					}
					if( hasPro == true && convolve == true )
					{
						cubeCamera.hdr = true;
					}
					if( hasPro == false  && convolve == true )
					{
						cubeCamera.hdr = false;
					}
			}
	
	}

	IEnumerator ConvolveIrradiance()
	{

		if (goConvolveIrradiance && EditorApplication.isPlaying)
		{

			CameraSetup(true);

			StartCoroutine(ConvolveDiffuseCubeMap()); 
		}

		Resources.UnloadUnusedAssets();
		AssetDatabase.Refresh();
		yield return new WaitForEndOfFrame();
		
	}

	IEnumerator ConvolveRadiance()
	{
		
		if (goConvolveRadiance && EditorApplication.isPlaying)
		{
			
			CameraSetup(true);

			StartCoroutine(ConvolveSpecularCubeMap()); 

		}

		Resources.UnloadUnusedAssets();
		AssetDatabase.Refresh();
		yield return new WaitForEndOfFrame();
		
	}

	IEnumerator ConvolveDiffuseCubeMap()
	{
		int size = 0;
		int samples = 0;
		size = CubeSizeSetup(true);

		if(irradianceModel == irradianceEnum.SphereUniform)
		{
			if(diffuseSamples == qualitySamples.Low)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Sphere 64"));
			}
			if(diffuseSamples == qualitySamples.Medium)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Sphere 64"));
			}
			if(diffuseSamples == qualitySamples.High)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Sphere 64"));
			}
		}
		if(irradianceModel == irradianceEnum.HemisphereUniform)
		{
			if(diffuseSamples == qualitySamples.Low)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Hemisphere 64"));
			}
			if(diffuseSamples == qualitySamples.Medium)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Hemisphere 128"));
			}
			if(diffuseSamples == qualitySamples.High)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Hemisphere 256"));
			}
		}
		if(irradianceModel == irradianceEnum.HemisphereCosine)
		{
			if(diffuseSamples == qualitySamples.Low)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Cosine 64"));
			}
			if(diffuseSamples == qualitySamples.Medium)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Cosine 128"));
			}
			if(diffuseSamples == qualitySamples.High)
			{
				convolveDiffuseSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Irradiance/Cosine 256"));
			}
		}

		convolveDiffuseSkybox.SetTexture("_DiffCubeIBL", diffuseCube);
		convolveDiffuseSkybox.SetInt("_diffuseSize", size);

		UnityEngine.RenderSettings.skybox = convolveDiffuseSkybox;
			
		Cubemap tempCube = new Cubemap(size, TextureFormat.ARGB32, false);
			
		//cubeCamera.RenderToCubemap(tempCube);

		yield return StartCoroutine(Capture(tempCube, CubemapFace.PositiveZ, cubeCamera));
		yield return StartCoroutine(Capture(tempCube, CubemapFace.PositiveX, cubeCamera));
		yield return StartCoroutine(Capture(tempCube, CubemapFace.NegativeX, cubeCamera));
		yield return StartCoroutine(Capture(tempCube, CubemapFace.NegativeZ, cubeCamera));
		yield return StartCoroutine(Capture(tempCube, CubemapFace.PositiveY, cubeCamera));
		yield return StartCoroutine(Capture(tempCube, CubemapFace.NegativeY, cubeCamera));

		// v0.035 this fix the ugly mipmap transition
		//tempCube.filterMode = FilterMode.Trilinear;
		//tempCube.wrapMode = TextureWrapMode.Clamp;
			
		tempCube.Apply();

		diffuseCube = tempCube;

		string convolvedDiffusePath = GetOutPutPath(diffuseCube,true);
			
		AssetDatabase.CreateAsset(diffuseCube, convolvedDiffusePath);
		SerializedObject serializedCubemap = new SerializedObject(diffuseCube);
		SetLinearSpace(ref serializedCubemap, false);

		yield return StartCoroutine(CaptureFinished());
	}
	
	IEnumerator ConvolveSpecularCubeMap()
	{
		int size = 0;
		int samples = 0;
		size = CubeSizeSetup(false);

		if(radianceModel == radianceEnum.BlinnPhong)
		{
			if(specularSamples == qualitySamples.Low)
			{
				convolveSpecularSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Radiance/Blinn 64"));
			}
			if(specularSamples == qualitySamples.Medium)
			{
				convolveSpecularSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Radiance/Blinn 128"));
			}
			if(specularSamples == qualitySamples.High)
			{
				convolveSpecularSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Radiance/Blinn 256"));
			}
		}

		if(radianceModel == radianceEnum.GGX)
		{
			if(specularSamples == qualitySamples.Low)
			{
				convolveSpecularSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Radiance/GGX 64"));
			}
			if(specularSamples == qualitySamples.Medium)
			{
				convolveSpecularSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Radiance/GGX 128"));
			}
			if(specularSamples == qualitySamples.High)
			{
				convolveSpecularSkybox = new Material(Shader.Find("Hidden/Antonov Suit/Radiance/GGX 256"));
			}
		}

		convolveSpecularSkybox.SetInt("_specularSize", size);
		convolveSpecularSkybox.SetTexture("_SpecCubeIBL", specularCube);

		UnityEngine.RenderSettings.skybox = convolveSpecularSkybox;

		Cubemap tempCube = new Cubemap(size, TextureFormat.ARGB32, true);

		for(int mip = 0; (size >> mip) > 0; mip++)
		{

			// v0.035 better way to get exponent with different cubemap size
			float minExponent = 0.01f;

			float exponent = Mathf.Max( (float)specularExponent / (float)size * (float)mip, minExponent );

			/*
			float[] expVal = new float [] {
				0.01f,0.1f,0.2f,0.3f,0.4f,0.5f,0.6f,0.7f,0.8f,0.9f,1.0f
			};

			float exponent = expVal[mip];

			convolveSpecularSkybox.SetFloat("_Shininess", exponent );
			*/

			if( mip == 0 )
			{
				convolveSpecularSkybox.SetFloat("_Shininess", 0.01f);
			}
			if( mip != 0 && radianceModel == radianceEnum.GGX)
			{
				convolveSpecularSkybox.SetFloat("_Shininess", exponent + 0.05f);
			}
			if( mip != 0 && radianceModel == radianceEnum.BlinnPhong)
			{
				convolveSpecularSkybox.SetFloat("_Shininess", exponent);
			}

			yield return StartCoroutine(CaptureImportanceSample(tempCube, CubemapFace.PositiveZ, cubeCamera,mip));
			yield return StartCoroutine(CaptureImportanceSample(tempCube, CubemapFace.PositiveX, cubeCamera,mip));
			yield return StartCoroutine(CaptureImportanceSample(tempCube, CubemapFace.NegativeX, cubeCamera,mip));
			yield return StartCoroutine(CaptureImportanceSample(tempCube, CubemapFace.NegativeZ, cubeCamera,mip));
			yield return StartCoroutine(CaptureImportanceSample(tempCube, CubemapFace.PositiveY, cubeCamera,mip));
			yield return StartCoroutine(CaptureImportanceSample(tempCube, CubemapFace.NegativeY, cubeCamera,mip));

		}

		// v0.035 this fix the ugly mipmap transition
		tempCube.filterMode = FilterMode.Trilinear;
		tempCube.wrapMode = TextureWrapMode.Clamp;

		tempCube.Apply(false);

		if (SystemInfo.graphicsShaderLevel != 50)
		{
			tempCube.SmoothEdges(smoothEdge);
		}

		specularCube = tempCube;

		string convolvedSpecularPath = GetOutPutPath(specularCube,false);
	
		AssetDatabase.CreateAsset(specularCube, convolvedSpecularPath);
		SerializedObject serializedCubemap = new SerializedObject(specularCube);
		SetLinearSpace(ref serializedCubemap, false);

		yield return StartCoroutine(CaptureFinished());
	}

	// This is the coroutine that creates the cubemap images
	IEnumerator CreateCubeMap(bool diffuse)
	{

		int size;
		if(diffuse)
		{
			size = CubeSizeSetup(true);
		}
		else
		{
			size = CubeSizeSetup(false);
		}

		Cubemap cubemap = new Cubemap(size, TextureFormat.ARGB32, true);

		yield return StartCoroutine(Capture(cubemap, CubemapFace.PositiveZ, cubeCamera));
		yield return StartCoroutine(Capture(cubemap, CubemapFace.PositiveX, cubeCamera));
		yield return StartCoroutine(Capture(cubemap, CubemapFace.NegativeX, cubeCamera));
		yield return StartCoroutine(Capture(cubemap, CubemapFace.NegativeZ, cubeCamera));
		yield return StartCoroutine(Capture(cubemap, CubemapFace.PositiveY, cubeCamera));
		yield return StartCoroutine(Capture(cubemap, CubemapFace.NegativeY, cubeCamera));

		// v0.035 this fix the ugly mipmap transition
		//cubemap.filterMode = FilterMode.Trilinear;
		cubemap.wrapMode = TextureWrapMode.Clamp;

		cubemap.Apply();

		if(diffuse)
		{
			diffuseCube = cubemap;

			if (SystemInfo.graphicsShaderLevel != 50)
			{
				diffuseCube.SmoothEdges(smoothEdge);
			}
			string diffusePath = GetOutPutPath(diffuseCube,true);

			AssetDatabase.CreateAsset(diffuseCube, diffusePath);
			SerializedObject serializedCubemap = new SerializedObject(diffuseCube);
			SetLinearSpace(ref serializedCubemap, false);
		}
		else
		{
			specularCube = cubemap;
			if (SystemInfo.graphicsShaderLevel != 50)
			{
				specularCube.SmoothEdges(smoothEdge);
			}
			string specularPath = GetOutPutPath(specularCube,false);

			AssetDatabase.CreateAsset(specularCube, specularPath);
			SerializedObject serializedCubemap = new SerializedObject(specularCube);
			SetLinearSpace(ref serializedCubemap, false);
		}

		// Re-enable the renderer
		if(renderer) 
		{
			renderer.enabled = true;
		}

		yield return StartCoroutine(CaptureFinished());
	}
	
	IEnumerator CaptureFinished()
	{
		done = true;
		yield return null;
	}
	#endif
	/*
	public Color AverageColor(Cubemap cube,CubemapFace face)
	{

		Color[] texColors = cube.GetPixels(face);
		float total = texColors.Length;
		
		float r = 0; 
		float g = 0; 
		float b = 0;
		float a = 0;
		for (int i = 0; i < total; i++) 
		{
			r += texColors[i].r;
			g += texColors[i].g;
			b += texColors[i].b;
			a += texColors[i].a;
		}

		return new Color(r/total, g/total, b/total, a/total);
	}
*/
	// Update is called once per frame
	void Update () 
	{

		#if UNITY_EDITOR
		previewMaterial.SetTexture("_DiffCubeIBL", diffuseCube);
		previewMaterial.SetTexture("_SpecCubeIBL", specularCube);
		previewMaterial.SetVector("_exposureIBL", new Vector4(specularExposure,diffuseExposure,0,0));

		if (EditorApplication.isPlaying)
		{
			if (previewProbe.GetComponent<MeshRenderer>().enabled)
				previewProbe.GetComponent<MeshRenderer>().enabled = false;
		}
		else
		{

			if (!previewProbe.GetComponent<MeshRenderer>().enabled)
				previewProbe.GetComponent<MeshRenderer>().enabled = true;

		}
		#endif

		int size = CubeSizeSetup(false);

		//Texture2D lodTest = new Texture2D(size,size);

		float lod =  Mathf.Log(size*size) - 2;
		specularExponent = (int)lod;

		//specularExponent = lodTest.mipmapCount;

		cubePos = this.transform.position;

		#if UNITY_EDITOR
		emptyCube = Resources.Load("emptyCube", typeof( Cubemap ) ) as Cubemap;

		if (goBake && EditorApplication.isPlaying == true)
		{
			if(bakeDirectAndIBL == false)
			{
				diffuseCube = emptyCube;
				specularCube = emptyCube;
				
				//Shader.SetGlobalTexture("_DiffCubeIBL", diffuseCube);
				//Shader.SetGlobalTexture("_SpecCubeIBL", diffuseCube);
			}
		}
		if (UnityEditor.EditorApplication.isPlaying && goBake)
		{
			StartCoroutine(Bake());
			goBake = false;
		}
		if (UnityEditor.EditorApplication.isPlaying && goConvolveIrradiance )
		{
			StartCoroutine(ConvolveIrradiance());
			goConvolveIrradiance = false;
		}
		if (UnityEditor.EditorApplication.isPlaying && goConvolveRadiance )
		{
			StartCoroutine(ConvolveRadiance());
			goConvolveRadiance = false;
		}
		if (!UnityEditor.EditorApplication.isPlaying)
		{
			goBake = false;
			
			goConvolveIrradiance = false;
			goConvolveRadiance = false;
		}
		else if (done)
		{
			CleanUp();
			UnityEditor.EditorApplication.isPlaying = false;    
		}
		#endif

		//Shader.SetGlobalInt("_lodSpecCubeIBL", specularExponent);
		//Shader.SetGlobalInt("_specularSize", 256);	
		//Shader.SetGlobalInt("_specSamples",64);

		foreach (GameObject cubeMeshes  in Meshes )
		{
			
			Renderer[] renderers = cubeMeshes.GetComponentsInChildren<Renderer>();
			
			foreach (Renderer mr in renderers) 
			{	
				this.m_materials = mr.renderer.sharedMaterials;
				
				foreach( Material mat in this.m_materials ) 
				{
					probeMatrix.SetTRS(transform.position, transform.rotation, Vector3.one);
					
					Matrix4x4 probeMatrixTranspose = probeMatrix.transpose;
					Matrix4x4 probeMatrixInverse = probeMatrix.inverse;

					mat.SetMatrix("_WorldToCube",probeMatrixTranspose);
					mat.SetMatrix("_WorldToCubeInverse",probeMatrixInverse);
					mat.SetVector("_cubemapPos", cubePos);

					switch(typeOfProjection)
					{
						case ProjectionType.InfiniteProjection:
							mat.DisableKeyword("ANTONOV_SPHERE_PROJECTION");
							mat.DisableKeyword("ANTONOV_BOX_PROJECTION");
							mat.EnableKeyword("ANTONOV_INFINITE_PROJECTION");
						break;
						case ProjectionType.SphereProjection:
							mat.DisableKeyword("ANTONOV_INFINITE_PROJECTION");
							mat.DisableKeyword("ANTONOV_BOX_PROJECTION");
							mat.EnableKeyword("ANTONOV_SPHERE_PROJECTION");
							mat.SetFloat("_cubemapScale", probeRadius);
							if(useAtten == true)
							{
								mat.EnableKeyword("ANTONOV_CUBEMAP_ATTEN");
								mat.SetFloat("_attenSphereRadius", attenSphereRadius);
							}
							else
							{
								mat.DisableKeyword("ANTONOV_CUBEMAP_ATTEN");
							}
						break;
						case ProjectionType.BoxProjection:
							mat.DisableKeyword("ANTONOV_INFINITE_PROJECTION");
							mat.DisableKeyword("ANTONOV_SPHERE_PROJECTION");
							mat.EnableKeyword("ANTONOV_BOX_PROJECTION");
							mat.SetVector("_cubemapBoxSize", probeBoxSize);
							if(useAtten == true)
							{
								mat.EnableKeyword("ANTONOV_CUBEMAP_ATTEN");
								mat.SetVector("_attenBoxSize", attenBoxSize);
							}
							else
							{
								mat.DisableKeyword("ANTONOV_CUBEMAP_ATTEN");
							}
						break;
					}

					mat.SetInt("_lodSpecCubeIBL", specularExponent);

					if(diffuseCube != null)
						mat.SetTexture("_DiffCubeIBL", diffuseCube);

					if(specularCube != null)
						mat.SetTexture("_SpecCubeIBL", specularCube);

					mat.SetVector("_exposureIBL", new Vector4(specularExposure,diffuseExposure,1,1));


					//mat.SetInt("_specularSize", 256);	
					//mat.SetInt("_specSamples",32);

				}
			}
		}
	}

	public void CleanUp()
	{
		foreach (GameObject cubeCamera in GameObject.FindObjectsOfType<GameObject>())
		{
			if (cubeCamera.name == "CubemapCamera")
			{
				DestroyImmediate(cubeCamera);
			}
		}
		goConvolveIrradiance = false;
		goConvolveRadiance = false;
		goBake = false;
	}

	void OnDrawGizmosSelected()
	{
		if (typeOfProjection == ProjectionType.SphereProjection) 
		{
			//Gizmos.color = Color.red;
			//Gizmos.DrawWireSphere(transform.position, innerprobeRadius );
			//Rotate the gizmos
			Gizmos.matrix = transform.localToWorldMatrix;
			Gizmos.color = Color.green;
			Gizmos.DrawWireSphere(transform.position, probeRadius );
			if(useAtten == true)
			{
				Gizmos.color = Color.yellow;
				Gizmos.DrawWireSphere(transform.position, attenSphereRadius );
			}
		}
		if (typeOfProjection == ProjectionType.BoxProjection) 
		{
			//Gizmos.color = Color.yellow;
			//Gizmos.DrawWireCube(transform.position, envInnerBox );


			//Rotate the gizmos
			Gizmos.matrix = transform.localToWorldMatrix;
			Gizmos.color = Color.blue;
			Gizmos.DrawWireCube(transform.position, probeBoxSize );
			if(useAtten == true)
			{
				Gizmos.color = Color.yellow;
				Gizmos.DrawWireCube(transform.position, attenBoxSize );
			}
		}
	}

	public void OnDrawGizmos()
	{
		Gizmos.DrawIcon(transform.position, "../Antonov Suit/Resources/cGizmo.tga", true);
	}

}
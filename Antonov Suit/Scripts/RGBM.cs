// RGBM encoding for Unity Free user
//Created by Charles Greivelding

using UnityEngine;
using System.Collections;

public class RGBM : MonoBehaviour 
{
	private Shader shader;
	private static Texture2D rtBuffer;
	private  Material material;
	private Camera camera;

	public static void FullScreenQuad(Material renderMat)
	{
		GL.PushMatrix();
		for (var i = 0; i < renderMat.passCount; ++i) 
		{
			renderMat.SetPass(i);
			GL.LoadOrtho();
			GL.Begin(GL.QUADS); // Quad
			GL.Color(new Color(1,1,1,1));
			GL.MultiTexCoord(0, new Vector3(0, 0, 0));
			GL.Vertex3(0,0,0);
			GL.MultiTexCoord(0, new Vector3(0, 1, 0));
			GL.Vertex3(0,1,0);
			GL.MultiTexCoord(0, new Vector3(1, 1, 0));
			GL.Vertex3(1,1,0);
			GL.MultiTexCoord(0, new Vector3(1, 0, 0));
			GL.Vertex3(1,0,0);
			GL.End();
		}
		GL.PopMatrix();
	}

	// Use this for initialization
	private void Start () 
	{
		camera = this.camera;
		// Init shader and material
		shader = Shader.Find("Hidden/RGBM");
		material = new Material(shader);

		// Init our render texture
		rtBuffer = new Texture2D(Screen.width, Screen.height, TextureFormat.ARGB32, false);

	}


	// Update is called once per frame
	private void Update () 
	{
		// Fill the _MainTex with our render texture
		material.SetTexture("_MainTex", rtBuffer);
	}

	private void OnPostRender()
	{

		rtBuffer.Resize(Screen.width, Screen.height, TextureFormat.ARGB32, false);
		rtBuffer.ReadPixels(new Rect(0,0,Screen.width,Screen.height), 0, 0);
		rtBuffer.Apply();

		// Draw a quad with our material filled with our render texture 
		FullScreenQuad(material);
	}
}

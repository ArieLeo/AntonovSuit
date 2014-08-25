// Created by Charles Greivelding

#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.IO;

[CustomEditor(typeof(AntonovSuitProbe))]

public class AntonovSuitProbeEditor : Editor
{



	private SerializedObject m_AntonovSuitProbe;
	AntonovSuitProbe m_target;

	private SerializedProperty m_cubemapRadius;
	private SerializedProperty m_cubemapBoxSize;
	private SerializedProperty m_diffuseSamples;
	private SerializedProperty m_specularSamples;
	private SerializedProperty m_cubemapFolder;
	private SerializedProperty m_cubemapName;
	private SerializedProperty m_diffuseSize;
	private SerializedProperty m_specularSize;
	private SerializedProperty m_smoothEdge;
	private SerializedProperty m_edgeScale;
	private SerializedProperty m_Meshes;
	private SerializedProperty m_specularExposure;
	private SerializedProperty m_diffuseExposure;

	private SerializedProperty m_irradianceModel;
	private SerializedProperty m_radianceModel;
	private SerializedProperty m_projectionType;

	//private SerializedProperty m_bakeDirectAndIBL;

	//Attenuation
	private SerializedProperty m_atten;
	private SerializedProperty m_attenRadius;
	private SerializedProperty m_attenBoxSize;

	private Object diffuseCubeObject;
	private Object specularCubeObject;

	private Object test;

	static bool c_showCube = true;
	static bool c_showSmoothEdge = true;

	static bool c_showSphereProjection = false;
	static bool c_showBoxProjection = false;

	void OnEnable()
	{
		m_target = (AntonovSuitProbe)target;
		m_AntonovSuitProbe = new SerializedObject(target);

		m_cubemapRadius = m_AntonovSuitProbe.FindProperty("probeRadius");
		m_cubemapBoxSize = m_AntonovSuitProbe.FindProperty("probeBoxSize");

		m_diffuseSamples = m_AntonovSuitProbe.FindProperty("diffuseSamples");
		m_specularSamples = m_AntonovSuitProbe.FindProperty("specularSamples");
		
		m_cubemapFolder = m_AntonovSuitProbe.FindProperty("cubemapFolder");
		m_cubemapName = m_AntonovSuitProbe.FindProperty("cubemapName");
		m_diffuseSize = m_AntonovSuitProbe.FindProperty("diffuseSize");
		m_specularSize = m_AntonovSuitProbe.FindProperty("specularSize");
		m_smoothEdge = m_AntonovSuitProbe.FindProperty("smoothEdge");
		m_edgeScale = m_AntonovSuitProbe.FindProperty("edgeScale");
		m_Meshes = m_AntonovSuitProbe.FindProperty("Meshes");

		m_irradianceModel = m_AntonovSuitProbe.FindProperty("irradianceModel");
		m_radianceModel = m_AntonovSuitProbe.FindProperty("radianceModel");
		m_projectionType = m_AntonovSuitProbe.FindProperty("typeOfProjection");

		m_atten = m_AntonovSuitProbe.FindProperty("useAtten");
		m_attenRadius = m_AntonovSuitProbe.FindProperty("attenSphereRadius");
		m_attenBoxSize = m_AntonovSuitProbe.FindProperty("attenBoxSize");

		m_diffuseExposure = m_AntonovSuitProbe.FindProperty("diffuseExposure");
		m_specularExposure = m_AntonovSuitProbe.FindProperty("specularExposure");

		//m_bakeDirectAndIBL = m_AntonovSuitProbe.FindProperty("bakeDirectAndIBL");
	}

	[MenuItem ("Antonov Suit/GameObject/Cubemap Probe")]
	public static  AntonovSuitProbe addAntonovSuitProbe() 
	{
		GameObject go = new GameObject("AntonovSuitProbe");
		go.AddComponent("AntonovSuitProbe");
		//go.renderer.sharedMaterial = new Material(Shader.Find("Hidden/Probe"));


		Selection.activeGameObject = go;
		AntonovSuitProbe s_AntonovSuitProbe = go.GetComponent<AntonovSuitProbe>();

		Undo.RegisterCreatedObjectUndo(go, "Add ImageReflection");
		return s_AntonovSuitProbe;
	}

	public override void OnInspectorGUI()
	{
		GUIStyle buttonStyle = new GUIStyle(GUI.skin.button);
		buttonStyle.margin = new RectOffset(4,4,8,8);
		buttonStyle.padding = new RectOffset(8, 8, 8, 8);

		Texture2D logo = Resources.Load("logo", typeof(Texture2D))as Texture2D;

		EditorGUILayout.Space();
		GUILayout.Label( logo,GUILayout.Width(128),GUILayout.Height(128));
		
		EditorGUILayout.Space();
		GUILayout.Label("Baking Settings", EditorStyles.boldLabel);
		EditorGUILayout.Space();

		EditorGUI.indentLevel += 1;

			EditorGUILayout.PropertyField(m_cubemapFolder, new GUIContent("Output Path"));
			EditorGUILayout.PropertyField(m_cubemapName, new GUIContent("Cubemap Name"));

			c_showCube = EditorGUILayout.Foldout(c_showCube, "Cubemap Settings" );
			if(c_showCube)
			{
				EditorGUI.indentLevel += 1;
					//EditorGUILayout.PropertyField(m_diffuseSize, new GUIContent("Diffuse Face Size"));

					m_diffuseSize.enumValueIndex = (int)(AntonovSuitProbe.facesSize)EditorGUILayout.EnumPopup("Diffuse Face Size", (AntonovSuitProbe.facesSize)AntonovSuitProbe.facesSize.GetValues(typeof(AntonovSuitProbe.facesSize)).GetValue(m_diffuseSize.enumValueIndex));

					m_specularSize.enumValueIndex = (int)(AntonovSuitProbe.facesSize)EditorGUILayout.EnumPopup("Specular Face Size", (AntonovSuitProbe.facesSize)AntonovSuitProbe.facesSize.GetValues(typeof(AntonovSuitProbe.facesSize)).GetValue(m_specularSize.enumValueIndex));

					//EditorGUILayout.PropertyField(m_specularSize, new GUIContent("Specular Face Size"));
				EditorGUI.indentLevel -= 1;
			}
			c_showSmoothEdge = EditorGUILayout.Foldout(c_showSmoothEdge, "Smooth Edge Settings (DX9)" );	
			if(c_showSmoothEdge)
			{
				EditorGUI.indentLevel += 1;
					EditorGUILayout.PropertyField(m_smoothEdge, new GUIContent("Edge Width"));
					EditorGUILayout.PropertyField(m_edgeScale, new GUIContent("Edge Scale"));
				EditorGUI.indentLevel -= 1;
			}	
		EditorGUI.indentLevel -= 1;

		EditorGUILayout.BeginVertical();
		//EditorGUILayout.PropertyField(m_bakeDirectAndIBL, new GUIContent("Bake IBL"));
		if (GUILayout.Button("Bake Probe", buttonStyle))
		{
			m_target.bakeDirectAndIBL = false;
			m_target.InitCreateCube();
			
		}
		if (GUILayout.Button("Bake Probe With IBL", buttonStyle))
		{
			m_target.bakeDirectAndIBL = true;
			m_target.InitCreateCube();	
		}
		EditorGUILayout.EndVertical();

		EditorGUILayout.Space();
		GUILayout.Label("Convolution Settings", EditorStyles.boldLabel);
		EditorGUILayout.Space();

		GUIStyle convolveStyle = new GUIStyle(GUI.skin.button);
		convolveStyle.fixedWidth = 128;
		convolveStyle.margin = new RectOffset(8,0,0,0);
		convolveStyle.padding = new RectOffset(8, 8, 16, 16);
		//convolveStyle.stretchWidth = false;
		//convolveStyle.stretchHeight = false;

		EditorGUILayout.BeginHorizontal();

			EditorGUILayout.BeginVertical();
				EditorGUI.indentLevel += 1;

				m_diffuseSamples.enumValueIndex = (int)(AntonovSuitProbe.qualitySamples)EditorGUILayout.EnumPopup("Diffuse Quality", (AntonovSuitProbe.qualitySamples)AntonovSuitProbe.qualitySamples.GetValues(typeof(AntonovSuitProbe.qualitySamples)).GetValue(m_diffuseSamples.enumValueIndex));

				m_irradianceModel.enumValueIndex = (int)(AntonovSuitProbe.irradianceEnum)EditorGUILayout.EnumPopup("Diffuse Model :", (AntonovSuitProbe.irradianceEnum)AntonovSuitProbe.irradianceEnum.GetValues(typeof(AntonovSuitProbe.irradianceEnum)).GetValue(m_irradianceModel.enumValueIndex));

				EditorGUI.indentLevel -= 1;
			EditorGUILayout.EndVertical();
	
			if (GUILayout.Button("Convolve Diffuse", convolveStyle))
			{
			
				m_target.InitConvolveIrradianceCube();
				
			}

		EditorGUILayout.EndHorizontal();

		EditorGUILayout.Space();

		EditorGUILayout.BeginHorizontal();

		EditorGUILayout.BeginVertical();
		EditorGUI.indentLevel += 1;

		m_specularSamples.enumValueIndex = (int)(AntonovSuitProbe.qualitySamples)EditorGUILayout.EnumPopup("Specular Quality", (AntonovSuitProbe.qualitySamples)AntonovSuitProbe.qualitySamples.GetValues(typeof(AntonovSuitProbe.qualitySamples)).GetValue(m_specularSamples.enumValueIndex));

			m_radianceModel.enumValueIndex = (int)(AntonovSuitProbe.radianceEnum)EditorGUILayout.EnumPopup("Specular Model :", (AntonovSuitProbe.radianceEnum)AntonovSuitProbe.radianceEnum.GetValues(typeof(AntonovSuitProbe.radianceEnum)).GetValue(m_radianceModel.enumValueIndex));

		EditorGUI.indentLevel -= 1;
		EditorGUILayout.EndVertical();

			if (GUILayout.Button("Convolve Specular", convolveStyle))
			{
				
				m_target.InitConvolveRadianceCube();
				
			}
		EditorGUILayout.EndHorizontal();
	
		EditorGUILayout.Space();
		GUILayout.Label("Probe Settings", EditorStyles.boldLabel);
		EditorGUILayout.Space();
		
		EditorGUILayout.BeginVertical();
		EditorGUI.indentLevel += 1;
		EditorGUILayout.PropertyField(m_Meshes, new GUIContent("Cubemap probe assigned objects"),true);
		EditorGUI.indentLevel -= 1;
		EditorGUILayout.EndVertical();

		EditorGUILayout.Space();
		//m_target.typeOfProjection = (AntonovSuitProbe.ProjectionType)EditorGUILayout.EnumPopup ("Cubemap Projection", m_target.typeOfProjection);

		m_projectionType.enumValueIndex = (int)(AntonovSuitProbe.ProjectionType)EditorGUILayout.EnumPopup("Cubemap Projection", (AntonovSuitProbe.ProjectionType)AntonovSuitProbe.ProjectionType.GetValues(typeof(AntonovSuitProbe.ProjectionType)).GetValue(m_projectionType.enumValueIndex));
	
		if(m_target.typeOfProjection == AntonovSuitProbe.ProjectionType.SphereProjection)
		{
			c_showSphereProjection = true;

			if(c_showSphereProjection == true)
			{
				EditorGUI.indentLevel += 1;
				EditorGUILayout.PropertyField(m_cubemapRadius, new GUIContent("Cubemap Radius"));

				EditorGUILayout.PropertyField(m_atten, new GUIContent("Use Attenuation"));
				if(m_atten.boolValue == true )
				{
					EditorGUI.indentLevel += 1;
					EditorGUILayout.PropertyField(m_attenRadius, new GUIContent("Attenuation Radius"));
					EditorGUI.indentLevel -= 1;
				}
				EditorGUI.indentLevel -= 1;
			}
		}
		if(m_target.typeOfProjection == AntonovSuitProbe.ProjectionType.BoxProjection)
		{
			c_showBoxProjection = true;

			if(c_showBoxProjection == true)
			{
				EditorGUI.indentLevel += 1;
				EditorGUILayout.PropertyField(m_cubemapBoxSize, new GUIContent("Cubemap Box Size"));

				EditorGUILayout.PropertyField(m_atten, new GUIContent("Use Attenuation"));
				if(m_atten.boolValue == true )
				{
					EditorGUI.indentLevel += 1;
					EditorGUILayout.PropertyField(m_attenBoxSize, new GUIContent("Attenuation Size"));
					EditorGUI.indentLevel -= 1;
				}
				EditorGUI.indentLevel -= 1;
			}
		}
		if(m_target.typeOfProjection == AntonovSuitProbe.ProjectionType.InfiniteProjection)
		{
			c_showSphereProjection = false;
			c_showBoxProjection = false;
		}
		
		EditorGUILayout.Space();

		GUILayout.Label("Diffuse Cubemap");
		EditorGUILayout.BeginHorizontal();	
			diffuseCubeObject = EditorGUILayout.ObjectField(m_target.diffuseCube, typeof(Cubemap), false, GUILayout.MinHeight(64), GUILayout.MinWidth(64), GUILayout.MaxWidth(64));
			m_target.diffuseCube = (Cubemap)diffuseCubeObject;

		//Color myColor = m_target.diffuseCube.GetPixel(CubemapFace.NegativeX,m_target.diffuseSize,m_target.diffuseSize);
	
			EditorGUILayout.PropertyField(m_diffuseExposure, new GUIContent("Diffuse Exposure"));
		EditorGUILayout.EndHorizontal();


		GUILayout.Label("Specular Cubemap");
		EditorGUILayout.BeginHorizontal();
			specularCubeObject = EditorGUILayout.ObjectField(m_target.specularCube, typeof(Cubemap), false, GUILayout.MinHeight(64), GUILayout.MinWidth(64), GUILayout.MaxWidth(64));
			m_target.specularCube = (Cubemap)specularCubeObject;
			
			EditorGUILayout.PropertyField(m_specularExposure, new GUIContent("Specular Exposure"));

		EditorGUILayout.EndHorizontal();

		EditorGUILayout.Space();




		if(GUI.changed)
		{
			//EditorUtility.SetDirty (target);
		}
	
		m_AntonovSuitProbe.ApplyModifiedProperties();
	}
}
#endif

// Custom texture processor
// Made by Charles Greivelding 28.09.2013

#if UNITY_EDITOR
class AntonovSuitTextureProcessor extends AssetPostprocessor 
{
	function OnPreprocessTexture () 
	{
		if (assetPath.Contains("_COLOR") || assetPath.Contains("_ILLUM"))  
		{
        	var diffuseTextureImporter : TextureImporter = assetImporter;
        	diffuseTextureImporter.isReadable = true;
        	diffuseTextureImporter.textureType = TextureImporterType.Image;
        	diffuseTextureImporter.filterMode = FilterMode.Trilinear;
        	diffuseTextureImporter.anisoLevel = 9;
        	diffuseTextureImporter.textureFormat = TextureImporterFormat.DXT1;
        	diffuseTextureImporter.maxTextureSize  = 4096;
		}
		if (assetPath.Contains("_RGBA"))  
		{
        	var RGBAlphaTextureImporter : TextureImporter = assetImporter;
        	RGBAlphaTextureImporter.isReadable = true;
        	RGBAlphaTextureImporter.textureType = TextureImporterType.Image;
        	RGBAlphaTextureImporter.filterMode = FilterMode.Trilinear;
        	RGBAlphaTextureImporter.anisoLevel = 9;
        	RGBAlphaTextureImporter.textureFormat = TextureImporterFormat.DXT5;
        	RGBAlphaTextureImporter.maxTextureSize  = 4096;
		}
		if (assetPath.Contains("_RGB")) 
		{
        	var RGBTextureImporter : TextureImporter = assetImporter;
        	RGBTextureImporter.isReadable = true;
        	RGBTextureImporter.textureType = TextureImporterType.Advanced;
        	RGBTextureImporter.filterMode = FilterMode.Trilinear;
        	RGBTextureImporter.anisoLevel = 9;
        	RGBTextureImporter.linearTexture = true;
        	RGBTextureImporter.textureFormat = TextureImporterFormat.AutomaticCompressed;
        	RGBTextureImporter.maxTextureSize  = 4096;
		}
		if (assetPath.Contains("_LUT") || assetPath.Contains("_JITTER")) 
		{
        	var LUTTextureImporter : TextureImporter = assetImporter;
        	LUTTextureImporter.isReadable = true;
        	LUTTextureImporter.textureType = TextureImporterType.Advanced;
        	LUTTextureImporter.filterMode = FilterMode.Trilinear;
        	LUTTextureImporter.wrapMode = TextureWrapMode.Clamp;
        	LUTTextureImporter.anisoLevel = 9;
        	LUTTextureImporter.linearTexture = true;
        	LUTTextureImporter.textureFormat = TextureImporterFormat.AutomaticTruecolor;
        	LUTTextureImporter.maxTextureSize  = 512;
		}
		if (assetPath.Contains("_JITTER")) 
		{
        	var JITTERTextureImporter : TextureImporter = assetImporter;
        	JITTERTextureImporter.isReadable = true;
        	JITTERTextureImporter.textureType = TextureImporterType.Advanced;
        	JITTERTextureImporter.filterMode = FilterMode.Trilinear;
        	JITTERTextureImporter.wrapMode = TextureWrapMode.Repeat;
        	JITTERTextureImporter.anisoLevel = 9;
        	JITTERTextureImporter.linearTexture = true;
        	JITTERTextureImporter.textureFormat = TextureImporterFormat.AutomaticTruecolor;
        	JITTERTextureImporter.maxTextureSize  = 512;
		}
		if (assetPath.Contains("_NORM")) 
		{
        	var normalTextureImporter : TextureImporter = assetImporter;
        	normalTextureImporter.isReadable = true;
        	normalTextureImporter.textureType = TextureImporterType.Bump;
        	normalTextureImporter.filterMode = FilterMode.Trilinear;
        	normalTextureImporter.anisoLevel = 9;   
        	normalTextureImporter.textureFormat = TextureImporterFormat.AutomaticCompressed;
        	normalTextureImporter.maxTextureSize  = 4096;	
		}
	}
}
#endif
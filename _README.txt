ANTONOV SUIT
A physical based shading system for Unity 4
by Charles Greivelding Thomas

REQUIREMENTS

Antonov Suit needs Unity Free or Pro and version 4.5 or newer.
Antonov Suit Shaders needs a shader model 3.0 ( dx9 ) graphic card to run.

GITHUB INSTALLATION

Download Antonov Suit from https://github.com/cCharkes/AntonovSuit
Open the zip archive and extract the content of the "AntonovSuit-master" folder in your "Assets" folder of your Unity project.
Once extracted you will have a folder called "Antonov Suit" in your "Assets" folder (Assets/Antonov Suit).

HOW IT WORKS

Antonov Suit is a physical based shading system for Unity 4 and design for forward rendering.

It supports "Specular Color", "Metallic" and "Skin" workflow.

The "Specular Color" and "Metallic" workflow have their transparent and illum version.

Specular Color workflow :

It use the shader called Specular ("Anotonov Suit/Specular Workflow/Specular") and needs the following textures : 

_DIFF 	: Diffuse albedo.
_SPEC	: Specular albedo.
_NORM	: Normal map.
_RGB	: R = Alpha, G = Roughness, B = Occlusion.
_ILLUM	: Illum color. // Needed for self illuminated version

Metallic workflow :

It consist of three main component the "Dielectric" ("Anotonov Suit/Metallic Workflow/Dielectric"), the "Metallic" ("Anotonov Suit/Metallic Workflow/Metallic") and the "Metallic and Dielectric" ("Anotonov Suit/Metallic Workflow/Metallic and Dielectric") shader.

Dielectric shader is the non condictor material ( stone, brick, plastic etc ).

Metallic shader is the conductor material ( any kind of metal ).

Metallic and Dielectric shader have both properties.

In order to work the Metallic shaders needs the following textures : 

_COLOR	: Diffuse albedo and specular albedo.
_NORM	: Normal map.
_RGB	: R = Metallic, G = Roughness, B = Occlusion.

_RGBA	: R = Metallic, G = Roughness, B = Occlusion, A = Alpha. // Needed for transparent version

_ILLUM	: Illum color. // Needed for self illuminated version

Skin workflow :

_DIFF	: Diffuse albedo.
_NORM	: Normal map.
_RGB 	: G = Roughness, B = Occlusion.
_RGB 	: R = Cavity, G = Deepness of scattering, B = Back scattering Mask.

MicroBump_RGB	: Micro occlusion.
MicroBump_NORM 	: Micro detail en normal map.

All shaders also use a LUT texture as a geometric and fresnel term for the cubemap specular reflection.
"Specular Color" and "Metallic" workflow use the GGX_SMITH_LUT texture because they the GGX specular model for the direct lighting and the "Skin" workflow use the BLINN_SMITH_LUT because it use the Beckmann (similar to a Blinn distribution) specular model for the direct lighting.
Those LUT goes in the ENV_LUT texture slot.

The "Skin" workflow use an other LUT called SKIN_LUT for the diffuse direct lighting and goes to the SKIN_LUT texture slot.

THE PROBE TOOL

To drop the probe tool into your scene search for the top menu called "Anotonov Suit" then look for the "Cubemap Probe" object in "AntonovSuit/GameObject/Cubemap Probe".
Now you have an object called AntonovSuitProbe and if you select it you will see multiple options in the inspector.

	BAKING SETTINGS

		This is the place where you define the output path, the name of the cubemap, the size of the smooth edges ( for DX9 users ) and the size of the diffuse and specular face.
		All cubemap have "_DIFF" and "_SPEC" plus the world space position during the capture included after the name.

		You will two button, "Bake Probe" and "Bake Probe With IBL". 
		"Bake Probe" will capture the scene without any diffuse and specular cubemap. That usually the one you will need for a first capture. 
		"Bake Probe With IBL" will capture the existing diffuse and specular cubemap in the scene.

	CONVOLUTION SETTINGS - IMPORTANT : Once the baking is done you need to add your diffuse and spacular cubemap in the "Diffuse Cubemap" and "Specular Cubemap" slot if you do not do this you will not be able to convolve them.

		Antonv Suit use GPU Importance Sampling to convolve the cubemap making the process faster and allow a perfect match with the direct specular.
		You can choose the quality and also the model of the diffuse and specular convolution.

	PROBE SETTINGS

		In order to use the Antonov Suit shaders you need to assigned objects to the probe.
		The probe supports sphere and box projection and you can activate an attenuation factor to it.
		You will find "Diffuse Cubemap" and "Specular Cubemap" textures slot and exposure control of them.
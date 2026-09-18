#ifndef TOM_TOON_LIGHTING_INC
#define TOM_TOON_LIGHTING_INC

#include "TomToonBRDF.cginc"
#include "UnityGlobalIllumination.cginc"

struct TomMaterialData
{
	float3 albedo;
	float3 geometricNormalWS;
	float3 shadingNormalWS;
	float metallic;
	float roughness;
	float occlusion;
	float3 f0;
	float specularMask;
	float reflectionMask;
	float3 emission;
};

struct TomShadowData
{
	float sampledAttenuation;
	float physicalAttenuation;
};

struct TomRawLightData
{
	float3 direction;
	float3 color;
	float distanceAttenuation;
	float cookieAttenuation;
	float sampledShadowAttenuation;
	float physicalShadowAttenuation;
};

struct TomSurfaceLightTerms
{
	float artisticShadowAttenuation;
	float diffuseShadowAttenuation;
	float shadingNdotL;
	float geometricNdotL;
	float horizon;
	float toonVisibility;
};

struct TomLightingResult
{
	float3 diffuse;
	float3 specular;
};

half4 TomVertexGI(
	TomVertexData v,
	float3 positionWS,
	half3 normalWS,
	out half3 vertexLightDiffuse)
{
	half4 ambientOrLightmapUV = 0;
	vertexLightDiffuse = 0;

#if defined(LIGHTMAP_ON)
	ambientOrLightmapUV.xy = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
#elif UNITY_SHOULD_SAMPLE_SH
	#if defined(VERTEXLIGHT_ON)
		vertexLightDiffuse = Shade4PointLights(
			unity_4LightPosX0,
			unity_4LightPosY0,
			unity_4LightPosZ0,
			unity_LightColor[0].rgb,
			unity_LightColor[1].rgb,
			unity_LightColor[2].rgb,
			unity_LightColor[3].rgb,
			unity_4LightAtten0,
			positionWS,
			normalWS);
	#endif
	ambientOrLightmapUV.rgb = ShadeSHPerVertex(normalWS, 0.0);
#endif

#if defined(DYNAMICLIGHTMAP_ON)
	ambientOrLightmapUV.zw = v.uv2 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

	return ambientOrLightmapUV;
}

TomVaryings TomVert(TomVertexData v)
{
	TomVaryings o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_OUTPUT(TomVaryings, o);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.posCS = UnityObjectToClipPos(v.vertex);
	o.normalWS = UnityObjectToWorldNormal(v.normal);
	o.tangentWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	o.bitangentWS = normalize(cross(o.normalWS, o.tangentWS.xyz) * (v.tangent.w * unity_WorldTransformParams.w));
	o.uv0 = v.uv0;
	o.ambientOrLightmapUV = TomVertexGI(
		v,
		o.posWS,
		normalize(o.normalWS),
		o.vertexLightDiffuse);

	#define pos posCS
	UNITY_TRANSFER_LIGHTING(o, v.uv1);
	#undef pos
	UNITY_TRANSFER_FOG(o, o.posCS);
	return o;
}

float TomFaceOrientation(fixed faceSign)
{
	return faceSign >= 0.0 ? 1.0 : -1.0;
}

float3 TomNormalWS(TomVaryings i, float faceOrientation, float3 geometricNormalWS)
{
	float2 normalUV = i.uv0 * _NormalMap_ST.xy + _NormalMap_ST.zw;
	float2 detailUV = i.uv0 * _NormalMapDetail_ST.xy + _NormalMapDetail_ST.zw;
	float3 baseNormal = UnpackScaleNormal(SAMPLE_TEX2D(_NormalMap, normalUV), _NormalMapScale);
	float3 detailNormal = UnpackScaleNormal(SAMPLE_TEX2D_SAMPLER(_NormalMapDetail, _NormalMap, detailUV), _DetailNormalMapScale);
	float3 normalTS = BlendNormals(baseNormal, detailNormal);
	float3 tangentWS = normalize(i.tangentWS.xyz);
	float3 bitangentWS = normalize(i.bitangentWS) * faceOrientation;
	return normalize(
		normalTS.x * tangentWS
		+ normalTS.y * bitangentWS
		+ normalTS.z * geometricNormalWS);
}

float TomSurfaceAlpha(TomVaryings i, float mainAlpha)
{
	float2 alphaUV = i.uv0 * _AlphaMask_ST.xy + _AlphaMask_ST.zw;
	return mainAlpha * SAMPLE_TEX2D(_AlphaMask, alphaUV).r;
}

TomMaterialData TomGetDirectMaterialData(TomVaryings i, fixed faceSign)
{
	TomMaterialData material;
	float4 mainTex = SAMPLE_TEX2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw);
	clip(TomSurfaceAlpha(i, mainTex.a) - _Cutoff);

	float faceOrientation = TomFaceOrientation(faceSign);
	material.albedo = mainTex.rgb * _BaseColor.rgb;
	material.geometricNormalWS = normalize(i.normalWS) * faceOrientation;
	material.shadingNormalWS = TomNormalWS(i, faceOrientation, material.geometricNormalWS);

	float metallicMap = SAMPLE_TEX2D(_MetallicMap, i.uv0 * _MetallicMap_ST.xy + _MetallicMap_ST.zw).r;
	float roughnessMap = SAMPLE_TEX2D(_RoughnessMap, i.uv0 * _RoughnessMap_ST.xy + _RoughnessMap_ST.zw).r;
	material.metallic = saturate(_Metallic * metallicMap);
	material.roughness = max(saturate(_Roughness * roughnessMap + _RoughnessBias), 0.04);

	float dielectricF0 = TomIorToF0(_SpecularIOR);
	material.f0 = lerp(dielectricF0.xxx, material.albedo, material.metallic);
	material.specularMask = SAMPLE_TEX2D(_SpecularMask, i.uv0 * _SpecularMask_ST.xy + _SpecularMask_ST.zw).r;

	material.occlusion = 1.0;
	material.reflectionMask = 0.0;
	material.emission = 0.0;
	return material;
}

TomMaterialData TomGetBaseMaterialData(TomVaryings i, fixed faceSign)
{
	TomMaterialData material = TomGetDirectMaterialData(i, faceSign);
	float occlusionMap = SAMPLE_TEX2D(_OcclusionMap, i.uv0 * _OcclusionMap_ST.xy + _OcclusionMap_ST.zw).r;
	material.occlusion = lerp(1.0, saturate(occlusionMap), saturate(_OcclusionStrength));
	material.reflectionMask = SAMPLE_TEX2D(_ReflectionMask, i.uv0 * _ReflectionMask_ST.xy + _ReflectionMask_ST.zw).r;
	float3 emissionMask = SAMPLE_TEX2D(_EmissionMask, i.uv0 * _EmissionMask_ST.xy + _EmissionMask_ST.zw).rgb;
	material.emission = emissionMask * _EmissionColor.rgb * _EmissionIntensity;
	return material;
}

float TomSampleRamp(float value)
{
	float2 rampUV = float2(saturate(value), 0.5) * _RampTex_ST.xy + _RampTex_ST.zw;
	return SAMPLE_TEX2D(_RampTex, rampUV).r;
}

float TomShapeShadow(float physicalShadow)
{
	physicalShadow = saturate(physicalShadow);
	float halfSoftness = max(_ShadowSoftness, 0.001) * 0.5;
	float stylizedShadow = smoothstep(
		_ShadowThreshold - halfSoftness,
		_ShadowThreshold + halfSoftness,
		physicalShadow);
	return lerp(physicalShadow, stylizedShadow, saturate(_ShadowRemapStrength));
}

void TomSampleLightDistanceAndCookie(
	float3 positionWS,
	out float distanceAttenuation,
	out float cookieAttenuation)
{
	distanceAttenuation = 1.0;
	cookieAttenuation = 1.0;

#if defined(POINT)
	float3 lightCoord = mul(unity_WorldToLight, float4(positionWS, 1.0)).xyz;
	distanceAttenuation = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
#elif defined(SPOT)
	float4 lightCoord = mul(unity_WorldToLight, float4(positionWS, 1.0));
	distanceAttenuation = UnitySpotAttenuate(lightCoord.xyz);
	cookieAttenuation = (lightCoord.z > 0.0) * UnitySpotCookie(lightCoord);
#elif defined(POINT_COOKIE)
	float3 lightCoord = mul(unity_WorldToLight, float4(positionWS, 1.0)).xyz;
	distanceAttenuation = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r;
	cookieAttenuation = texCUBE(_LightTexture0, lightCoord).w;
#elif defined(DIRECTIONAL_COOKIE)
	float2 lightCoord = mul(unity_WorldToLight, float4(positionWS, 1.0)).xy;
	cookieAttenuation = tex2D(_LightTexture0, lightCoord).w;
#endif

	distanceAttenuation = saturate(distanceAttenuation);
	cookieAttenuation = saturate(cookieAttenuation);
}

TomShadowData TomGetShadowData(TomVaryings i)
{
	TomShadowData shadow;
	shadow.sampledAttenuation = saturate(UNITY_SHADOW_ATTENUATION(i, i.posWS));
	shadow.physicalAttenuation = shadow.sampledAttenuation;

#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
	half bakedAttenuation = UnitySampleBakedOcclusion(i.ambientOrLightmapUV.xy, i.posWS);
	float zDistance = dot(_WorldSpaceCameraPos - i.posWS, UNITY_MATRIX_V[2].xyz);
	float fadeDistance = UnityComputeShadowFadeDistance(i.posWS, zDistance);
	shadow.physicalAttenuation = UnityMixRealtimeAndBakedShadows(
		shadow.sampledAttenuation,
		bakedAttenuation,
		UnityComputeShadowFade(fadeDistance));
#endif

	shadow.physicalAttenuation = saturate(shadow.physicalAttenuation);
	return shadow;
}

TomRawLightData TomBuildRawLightData(
	float3 lightDirection,
	float3 lightColor,
	float distanceAttenuation,
	float cookieAttenuation,
	TomShadowData shadow,
	float intensity)
{
	TomRawLightData light;
	light.direction = normalize(lightDirection);
	light.color = lightColor * intensity;
	light.distanceAttenuation = distanceAttenuation;
	light.cookieAttenuation = cookieAttenuation;
	light.sampledShadowAttenuation = shadow.sampledAttenuation;
	light.physicalShadowAttenuation = shadow.physicalAttenuation;
	return light;
}

TomSurfaceLightTerms TomBuildSurfaceLightTerms(
	TomMaterialData material,
	TomRawLightData light)
{
	TomSurfaceLightTerms surface;
	surface.artisticShadowAttenuation = TomShapeShadow(light.physicalShadowAttenuation);
	surface.diffuseShadowAttenuation = lerp(
		1.0,
		surface.artisticShadowAttenuation,
		saturate(_ShadowStrength));

	surface.shadingNdotL = saturate(dot(material.shadingNormalWS, light.direction));
	surface.geometricNdotL = saturate(dot(material.geometricNormalWS, light.direction));
	float horizonFade = max(_NormalHorizonFade, 0.001);
	float shadingHorizon = smoothstep(0.0, horizonFade, surface.shadingNdotL);
	float geometricHorizon = smoothstep(0.0, horizonFade, surface.geometricNdotL);
	surface.horizon = shadingHorizon * geometricHorizon;

	float rampInput = surface.shadingNdotL * lerp(
		1.0,
		surface.diffuseShadowAttenuation,
		saturate(_UseRampForShadows));
	float ramp = TomSampleRamp(rampInput);
	float toonNdotL = lerp(surface.shadingNdotL, ramp, saturate(_UseRamp));
	float shadowOutsideRamp = lerp(
		surface.diffuseShadowAttenuation,
		1.0,
		saturate(_UseRampForShadows) * saturate(_UseRamp));
	surface.toonVisibility = toonNdotL
		* light.distanceAttenuation
		* light.cookieAttenuation
		* shadowOutsideRamp
		* surface.horizon;
	return surface;
}

TomLightingResult TomEvaluateDirectLight(
	TomMaterialData material,
	TomRawLightData light,
	TomSurfaceLightTerms surface,
	float3 viewDir)
{
	TomLightingResult result;
	float3 halfVector = light.direction + viewDir;
	float halfLengthSq = dot(halfVector, halfVector);
	float halfIsValid = step(0.000001, halfLengthSq);
	float3 halfDir = halfVector * rsqrt(max(halfLengthSq, 0.000001));
	float nDotV = saturate(dot(material.shadingNormalWS, viewDir));
	float nDotL = surface.shadingNdotL;
	float nDotH = saturate(dot(material.shadingNormalWS, halfDir)) * halfIsValid;
	float vDotH = saturate(dot(viewDir, halfDir)) * halfIsValid;
	float ggxBlend = saturate(_GGXSpecularBlend);

	float3 fresnel = halfIsValid > 0.5
		? TomFresnelSchlick(vDotH, material.f0, _FresnelStrength)
		: material.f0;
	float3 energyConservingDiffuse = (1.0 - fresnel) * (1.0 - material.metallic);
	float3 diffuseWeight;
	float3 specularBRDF;

	UNITY_BRANCH
	if (ggxBlend >= 0.999)
	{
		diffuseWeight = energyConservingDiffuse;
		specularBRDF = halfIsValid > 0.5 && surface.horizon > 0.0
			? TomEvaluateProductionGGX(
				nDotV,
				nDotL,
				nDotH,
				vDotH,
				material.roughness,
				material.f0,
				_FresnelStrength) * _SpecularColor.rgb * surface.horizon
			: 0.0;
	}
	else
	{
		float blinnLobe = pow(nDotH, max(_SpecularPower, 1.0)) * surface.horizon;
		float3 blinnSpecular = blinnLobe * _SpecularColor.rgb;

		UNITY_BRANCH
		if (ggxBlend <= 0.001)
		{
			diffuseWeight = 1.0.xxx;
			specularBRDF = blinnSpecular;
		}
		else
		{
			float3 ggxSpecular = halfIsValid > 0.5 && surface.horizon > 0.0
				? TomEvaluateProductionGGX(
					nDotV,
					nDotL,
					nDotH,
					vDotH,
					material.roughness,
					material.f0,
					_FresnelStrength) * _SpecularColor.rgb * surface.horizon
				: 0.0;
			diffuseWeight = lerp(1.0.xxx, energyConservingDiffuse, ggxBlend);
			specularBRDF = lerp(blinnSpecular, ggxSpecular, ggxBlend);
		}
	}

	result.diffuse = material.albedo * diffuseWeight * light.color * surface.toonVisibility;
	float specularShadow = lerp(
		1.0,
		surface.artisticShadowAttenuation,
		saturate(_SpecularShadowStrength));
	result.specular = specularBRDF
		* material.specularMask
		* _SpecularStrength
		* light.color
		* light.distanceAttenuation
		* light.cookieAttenuation
		* specularShadow;
	return result;
}

UnityGIInput TomBuildGIInput(
	TomVaryings i,
	TomMaterialData material,
	float3 viewDir,
	float3 lightDir,
	float engineAttenuation)
{
	UnityGIInput data;
	data.light.color = _LightColor0.rgb;
	data.light.dir = lightDir;
	data.light.ndotl = saturate(dot(material.shadingNormalWS, lightDir));
	data.worldPos = i.posWS;
	data.worldViewDir = viewDir;
	data.atten = engineAttenuation;

#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
	data.ambient = 0;
	data.lightmapUV = i.ambientOrLightmapUV;
#else
	data.ambient = i.ambientOrLightmapUV.rgb;
	data.lightmapUV = 0;
#endif

	data.probeHDR[0] = unity_SpecCube0_HDR;
	data.probeHDR[1] = unity_SpecCube1_HDR;
#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
	data.boxMin[0] = unity_SpecCube0_BoxMin;
#endif
#if defined(UNITY_SPECCUBE_BOX_PROJECTION)
	data.boxMax[0] = unity_SpecCube0_BoxMax;
	data.probePosition[0] = unity_SpecCube0_ProbePosition;
	data.boxMax[1] = unity_SpecCube1_BoxMax;
	data.boxMin[1] = unity_SpecCube1_BoxMin;
	data.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif
	return data;
}

float3 TomSHAtlasBlockUV(float3 volumeUV, float blockIndex)
{
	float3 grid = max(_TomSHVolumeGrid.xyz, 2.0);
	float atlasWidth = max(_TomSHVolumeGrid.w, grid.x * 7.0);
	return float3(
		(blockIndex * grid.x + 0.5 + volumeUV.x * (grid.x - 1.0)) / atlasWidth,
		(0.5 + volumeUV.y * (grid.y - 1.0)) / grid.y,
		(0.5 + volumeUV.z * (grid.z - 1.0)) / grid.z);
}

float4 TomEvaluateCustomSHVolume(float3 positionWS, float3 normalWS)
{
	float4 result = float4(0.0, 0.0, 0.0, 0.0);

	UNITY_BRANCH
	if (_TomSHVolumeParams.x >= 0.5)
	{
		float3 localPosition = mul(_TomSHWorldToLocal, float4(positionWS, 1.0)).xyz;
		float3 volumeUV = (localPosition - _TomSHBoundsMin.xyz) * _TomSHBoundsInvSize.xyz;
		float3 inside = step(0.0, volumeUV) * step(volumeUV, 1.0);
		float insideWeight = inside.x * inside.y * inside.z;
		float3 edgeDistance3 = min(volumeUV, 1.0 - volumeUV);
		float edgeDistance = min(edgeDistance3.x, min(edgeDistance3.y, edgeDistance3.z));
		float edgeFade = max(_TomSHVolumeParams.z, 0.0);
		float smoothWeight = smoothstep(0.0, max(edgeFade, 0.0001), edgeDistance);
		float hardWeight = 1.0 - step(0.0001, edgeFade);
		float weight = insideWeight * lerp(smoothWeight, 1.0, hardWeight);

		UNITY_BRANCH
		if (weight > 0.0)
		{
			float4 shAr = tex3D(_TomSHVolumeTex, TomSHAtlasBlockUV(volumeUV, 0.0));
			float4 shAg = tex3D(_TomSHVolumeTex, TomSHAtlasBlockUV(volumeUV, 1.0));
			float4 shAb = tex3D(_TomSHVolumeTex, TomSHAtlasBlockUV(volumeUV, 2.0));
			float4 shBr = tex3D(_TomSHVolumeTex, TomSHAtlasBlockUV(volumeUV, 3.0));
			float4 shBg = tex3D(_TomSHVolumeTex, TomSHAtlasBlockUV(volumeUV, 4.0));
			float4 shBb = tex3D(_TomSHVolumeTex, TomSHAtlasBlockUV(volumeUV, 5.0));
			float3 shC = tex3D(_TomSHVolumeTex, TomSHAtlasBlockUV(volumeUV, 6.0)).rgb;

			float4 normal4 = float4(normalWS, 1.0);
			float4 quadratic = normalWS.xyzz * normalWS.yzzx;
			float3 irradiance = 0.0;
			irradiance.r = dot(shAr, normal4) + dot(shBr, quadratic);
			irradiance.g = dot(shAg, normal4) + dot(shBg, quadratic);
			irradiance.b = dot(shAb, normal4) + dot(shBb, quadratic);
			irradiance += shC * (normalWS.x * normalWS.x - normalWS.y * normalWS.y);
			result = float4(max(irradiance, 0.0) * _TomSHVolumeParams.y, weight);
		}
	}

	return result;
}

float3 TomEvaluateIndirectDiffuse(
	TomVaryings i,
	TomMaterialData material,
	float3 viewDir,
	UnityGI gi)
{
#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
	float3 irradiance = max(gi.indirect.diffuse, 0.0);
#else
	float3 irradiance = lerp(
		_AmbientColor.rgb,
		max(gi.indirect.diffuse, 0.0),
		saturate(_LightProbeBlend));
	float4 customSH = TomEvaluateCustomSHVolume(
		i.posWS,
		material.shadingNormalWS);
	irradiance = lerp(
		irradiance,
		customSH.rgb,
		saturate(_CustomSHVolumeBlend) * customSH.a);
#endif

	float nDotV = saturate(dot(material.shadingNormalWS, viewDir));
	float3 fresnel = TomFresnelSchlick(nDotV, material.f0, _FresnelStrength);
	float3 energyConservingDiffuse = (1.0 - fresnel) * (1.0 - material.metallic);
	float3 diffuseWeight = lerp(1.0.xxx, energyConservingDiffuse, saturate(_GGXSpecularBlend));
	return material.albedo
		* diffuseWeight
		* irradiance
		* material.occlusion
		* _IndirectDiffuseIntensity;
}

float3 TomEvaluateVertexLightDiffuse(
	TomMaterialData material,
	float3 viewDir,
	float3 vertexLightDiffuse)
{
#if defined(VERTEXLIGHT_ON) && !defined(LIGHTMAP_ON)
	float nDotV = saturate(dot(material.geometricNormalWS, viewDir));
	float3 fresnel = TomFresnelSchlick(nDotV, material.f0, _FresnelStrength);
	float3 energyConservingDiffuse = (1.0 - fresnel) * (1.0 - material.metallic);
	float3 diffuseWeight = lerp(1.0.xxx, energyConservingDiffuse, saturate(_GGXSpecularBlend));
	return material.albedo
		* diffuseWeight
		* max(vertexLightDiffuse, 0.0)
		* max(_VertexLightIntensity, 0.0);
#else
	return 0.0;
#endif
}

float TomGetMainDirectOwnership()
{
	// Static Subtractive lightmaps already contain the main light's direct term.
#if defined(LIGHTMAP_ON) && defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK)
	return 0.0;
#else
	return 1.0;
#endif
}

float3 TomEvaluateProbeSpecular(
	UnityGIInput giInput,
	TomMaterialData material,
	float3 viewDir)
{
	float perceptualRoughness = lerp(
		saturate(_EnvironmentRoughness),
		material.roughness,
		saturate(_UseMaterialRoughnessForEnvironment));
	float smoothness = 1.0 - perceptualRoughness;
	Unity_GlossyEnvironmentData glossy = UnityGlossyEnvironmentSetup(
		smoothness,
		viewDir,
		material.shadingNormalWS,
		material.f0);
	float3 environment = UnityGI_IndirectSpecular(giInput, 1.0, glossy);

	float realRoughness = PerceptualRoughnessToRoughness(perceptualRoughness);
#if defined(UNITY_COLORSPACE_GAMMA)
	float surfaceReduction = 1.0 - 0.28 * realRoughness * perceptualRoughness;
#else
	float surfaceReduction = 1.0 / (realRoughness * realRoughness + 1.0);
#endif

	float reflectivity = max(max(material.f0.r, material.f0.g), material.f0.b);
	float grazingTerm = saturate(smoothness + reflectivity);
	float nDotV = saturate(dot(material.shadingNormalWS, viewDir));
	float3 unityFresnel = FresnelLerp(material.f0, grazingTerm.xxx, nDotV);
	float3 fresnel = saturate(lerp(material.f0, unityFresnel, _FresnelStrength));
	float specularOcclusion = lerp(
		1.0,
		material.occlusion,
		saturate(_SpecularOcclusionStrength));
	return environment * surfaceReduction * fresnel * specularOcclusion;
}

float3 TomApplyReflections(
	TomVaryings i,
	UnityGIInput giInput,
	TomMaterialData material,
	float3 viewDir,
	float mainShadow,
	float3 color)
{
	float mode = floor(_ReflectionMode + 0.5);
	float reflectionShadow = lerp(1.0, mainShadow, saturate(_ReflectionShadowStrength));

	UNITY_BRANCH
	if (mode == 1.0 || mode == 3.0)
	{
		float3 normalVS = mul((float3x3)UNITY_MATRIX_V, material.shadingNormalWS);
		float2 matCapUV = normalVS.xy * 0.5 + 0.5;
		matCapUV = matCapUV * _MatCap_ST.xy + _MatCap_ST.zw;
		float3 matCap = SAMPLE_TEX2D_LOD(_MatCap, float4(matCapUV, 0, 0), _MatCapMip).rgb;
		float matCapAmount = material.reflectionMask * _MatCapIntensity * reflectionShadow;
		float3 matCapMultiply = color * lerp(1.0, matCap * 2.0, matCapAmount);
		float3 matCapAdd = color + matCap * matCapAmount;
		color = lerp(matCapMultiply, matCapAdd, saturate(_MatCapBlendMode));
	}

	UNITY_BRANCH
	if (mode == 2.0 || mode == 3.0)
	{
		color += TomEvaluateProbeSpecular(giInput, material, viewDir)
			* material.reflectionMask
			* _EnvironmentIntensity
			* reflectionShadow;
	}
	return color;
}

float3 TomEvaluateRim(TomMaterialData material, float3 viewDir, float mainShadow)
{
	float rim = pow(saturate(1.0 - dot(material.shadingNormalWS, viewDir)), max(_RimPower, 0.01));
	float shadow = lerp(1.0, mainShadow, saturate(_RimShadowStrength));
	return rim * _RimStrength * _RimColor.rgb * shadow;
}

fixed4 TomFragBase(TomVaryings i, fixed faceSign : VFACE) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
	TomMaterialData material = TomGetBaseMaterialData(i, faceSign);
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS));
	float distanceAttenuation;
	float cookieAttenuation;
	TomSampleLightDistanceAndCookie(i.posWS, distanceAttenuation, cookieAttenuation);
	TomShadowData shadow = TomGetShadowData(i);
	TomRawLightData mainLight = TomBuildRawLightData(
		lightDir,
		_LightColor0.rgb,
		distanceAttenuation,
		cookieAttenuation,
		shadow,
		_MainLightIntensity);
	TomSurfaceLightTerms mainSurface = TomBuildSurfaceLightTerms(material, mainLight);
	TomLightingResult direct = TomEvaluateDirectLight(material, mainLight, mainSurface, viewDir);

	float engineAttenuation = mainLight.distanceAttenuation
		* mainLight.cookieAttenuation
		* mainLight.sampledShadowAttenuation;
	UnityGIInput giInput = TomBuildGIInput(
		i,
		material,
		viewDir,
		lightDir,
		engineAttenuation);
	UnityGI gi = UnityGlobalIllumination(giInput, 1.0, material.shadingNormalWS);
	float3 indirectDiffuse = TomEvaluateIndirectDiffuse(i, material, viewDir, gi);
	float3 vertexLightDiffuse = TomEvaluateVertexLightDiffuse(
		material,
		viewDir,
		i.vertexLightDiffuse);
	float mainDirectOwnership = TomGetMainDirectOwnership();
	direct.diffuse *= mainDirectOwnership;
	direct.specular *= mainDirectOwnership;

	float3 shadowTint = lerp(
		_ShadowColor.rgb,
		1.0,
		mainSurface.diffuseShadowAttenuation);
	shadowTint = lerp(1.0.xxx, shadowTint, mainDirectOwnership);
	float3 color = indirectDiffuse * shadowTint
		+ vertexLightDiffuse
		+ direct.diffuse
		+ direct.specular;
	color += TomEvaluateRim(material, viewDir, mainSurface.artisticShadowAttenuation);
	color = TomApplyReflections(
		i,
		giInput,
		material,
		viewDir,
		mainSurface.artisticShadowAttenuation,
		color);
	color += material.emission;

	fixed4 outputColor = float4(max(color, 0.0), 1.0);
	UNITY_APPLY_FOG(i.fogCoord, outputColor);
	return outputColor;
}

fixed4 TomFragAdd(TomVaryings i, fixed faceSign : VFACE) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
	TomMaterialData material = TomGetDirectMaterialData(i, faceSign);
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS));
	float distanceAttenuation;
	float cookieAttenuation;
	TomSampleLightDistanceAndCookie(i.posWS, distanceAttenuation, cookieAttenuation);
	TomShadowData shadow = TomGetShadowData(i);
	TomRawLightData light = TomBuildRawLightData(
		lightDir,
		_LightColor0.rgb,
		distanceAttenuation,
		cookieAttenuation,
		shadow,
		_AdditionalLightIntensity);
	TomSurfaceLightTerms surface = TomBuildSurfaceLightTerms(material, light);
	TomLightingResult direct = TomEvaluateDirectLight(material, light, surface, viewDir);

	fixed4 outputColor = float4(max(direct.diffuse + direct.specular, 0.0), 0.0);
	UNITY_APPLY_FOG(i.fogCoord, outputColor);
	return outputColor;
}

#endif

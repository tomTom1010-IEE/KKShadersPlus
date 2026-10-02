#ifndef TOM_TOON_LIGHTING_INC
#define TOM_TOON_LIGHTING_INC

#include "TomToonBRDF.cginc"
#include "TomToonStyle.cginc"
#include "UnityGlobalIllumination.cginc"

struct TomMaterialData
{
	float3 albedo;
	float3 geometricNormalWS;
	float3 shadingNormalWS;
	float3 mainNormalWS;
	float normalVariance;
	float4 layerMask;
	float secondaryToneMask;
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

float3 TomSafeDirection(float3 direction)
{
	// A scene without a main light may supply a zero vector.
	return direction * rsqrt(max(dot(direction, direction), 0.000001));
}

float3 TomNormalWS(TomVaryings i, float faceOrientation, float3 geometricNormalWS, out float3 mainNormalWS)
{
	float2 normalUV = i.uv0 * _NormalMap_ST.xy + _NormalMap_ST.zw;
	float2 detailUV = i.uv0 * _NormalMapDetail_ST.xy + _NormalMapDetail_ST.zw;
	float3 baseNormal = UnpackScaleNormal(SAMPLE_TEX2D(_NormalMap, normalUV), _NormalMapScale);
	float3 detailNormal = UnpackScaleNormal(SAMPLE_TEX2D_SAMPLER(_NormalMapDetail, _NormalMap, detailUV), _DetailNormalMapScale);
	float3 normalTS = BlendNormals(baseNormal, detailNormal);
	float3 tangentWS = normalize(i.tangentWS.xyz);
	float3 bitangentWS = normalize(i.bitangentWS) * faceOrientation;
	mainNormalWS = normalize(baseNormal.x * tangentWS + baseNormal.y * bitangentWS + baseNormal.z * geometricNormalWS);
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
	material.shadingNormalWS = TomNormalWS(i, faceOrientation, material.geometricNormalWS, material.mainNormalWS);
	float3 dx = ddx(material.shadingNormalWS);
	float3 dy = ddy(material.shadingNormalWS);
	material.normalVariance = 0.5 * (dot(dx, dx) + dot(dy, dy));
	float metallicMap;
	float roughnessMap;
	material.occlusion = 1.0;
	UNITY_BRANCH
	if (_UsePackedMaterialMap > 0.5)
	{
		float4 packed = SAMPLE_TEX2D_SAMPLER(_MaterialMap, _MainTex, i.uv0 * _MaterialMap_ST.xy + _MaterialMap_ST.zw);
		metallicMap = packed.r;
		roughnessMap = packed.g;
		material.occlusion = lerp(1.0, saturate(packed.b), saturate(_OcclusionStrength));
		material.specularMask = packed.a;
	}
	else
	{
		metallicMap = SAMPLE_TEX2D(_MetallicMap, i.uv0 * _MetallicMap_ST.xy + _MetallicMap_ST.zw).r;
		roughnessMap = SAMPLE_TEX2D(_RoughnessMap, i.uv0 * _RoughnessMap_ST.xy + _RoughnessMap_ST.zw).r;
		material.specularMask = SAMPLE_TEX2D(_SpecularMask, i.uv0 * _SpecularMask_ST.xy + _SpecularMask_ST.zw).r;
	}
	material.metallic = saturate(_Metallic * metallicMap);
	material.roughness = max(saturate(_Roughness * roughnessMap + _RoughnessBias), 0.04);
	float dielectricF0 = TomIorToF0(_SpecularIOR);
	material.f0 = lerp(dielectricF0.xxx, material.albedo, material.metallic);
	material.layerMask = 1.0;
	float reflectionMode = floor(_ReflectionMode + 0.5);
	bool matcapMultiply = (reflectionMode == 1.0 || reflectionMode == 3.0)
		&& _MatCapIntensity > 0.0 && _MatCapBlendMode < 0.5;
	bool needsLayers = _SecondaryToneStrength > 0.0 || matcapMultiply;
#if defined(UNITY_PASS_FORWARDBASE)
	needsLayers = needsLayers || _RimStrength > 0.0 || reflectionMode > 0.0;
#endif
	UNITY_BRANCH
	if (needsLayers)
		material.layerMask = SAMPLE_TEX2D_SAMPLER(_LayerMask, _MainTex, i.uv0 * _LayerMask_ST.xy + _LayerMask_ST.zw);
	material.secondaryToneMask = material.layerMask.r;
	material.reflectionMask = 0.0;
	bool needsReflectionMask = matcapMultiply;
#if defined(UNITY_PASS_FORWARDBASE)
	needsReflectionMask = reflectionMode > 0.0;
#endif
	UNITY_BRANCH
	if (needsReflectionMask)
		material.reflectionMask = SAMPLE_TEX2D(_ReflectionMask, i.uv0 * _ReflectionMask_ST.xy + _ReflectionMask_ST.zw).r;
	material.emission = 0.0;
	return material;
}

TomMaterialData TomGetBaseMaterialData(TomVaryings i, fixed faceSign)
{
	TomMaterialData material = TomGetDirectMaterialData(i, faceSign);
	UNITY_BRANCH
	if (_UsePackedMaterialMap < 0.5 && _OcclusionStrength > 0.0)
	{
		float occlusionMap = SAMPLE_TEX2D(_OcclusionMap, i.uv0 * _OcclusionMap_ST.xy + _OcclusionMap_ST.zw).r;
		material.occlusion = lerp(1.0, saturate(occlusionMap), saturate(_OcclusionStrength));
	}
	UNITY_BRANCH
	if (_EmissionIntensity > 0.0)
	{
		float3 emissionMask = SAMPLE_TEX2D(_EmissionMask, i.uv0 * _EmissionMask_ST.xy + _EmissionMask_ST.zw).rgb;
		material.emission = emissionMask * _EmissionColor.rgb * _EmissionIntensity
			* lerp(1.0.xxx, material.albedo, saturate(_EmissionKeepCol));
	}
	return material;
}

float TomSampleRamp(float value, float secondaryMask)
{
	float ramp = lerp(_ToonShadeLevel, 1.0, TomSoftBand(value, _ToonThreshold, _ToonSoftness));
	UNITY_BRANCH
	if (_RampMode > 0.5)
	{
		float2 uv = float2(saturate(value), 0.5) * _RampTex_ST.xy + _RampTex_ST.zw;
		ramp = SAMPLE_TEX2D(_RampTex, uv).r;
	}
	UNITY_BRANCH
	if (_SecondaryToneStrength > 0.0 && secondaryMask > 0.0)
	{
		float2 uv = float2(saturate(value), 0.5) * _SecondaryRamp_ST.xy + _SecondaryRamp_ST.zw;
		float secondary = SAMPLE_TEX2D_SAMPLER(_SecondaryRamp, _MainTex, uv).r;
		ramp = lerp(ramp, secondary, saturate(_SecondaryToneStrength * secondaryMask));
	}
	return ramp;
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
	float ramp = light.physicalShadowAttenuation;
	UNITY_BRANCH
	if (_UseRamp > 0.0)
		ramp = TomSampleRamp(rampInput, material.secondaryToneMask);
	float toonNdotL = lerp(surface.shadingNdotL, ramp, saturate(_UseRamp));
	float shadowOutsideRamp = lerp(
		surface.diffuseShadowAttenuation,
		1.0,
		saturate(_UseRampForShadows) * saturate(_UseRamp));
	surface.toonVisibility = toonNdotL
		* light.distanceAttenuation
		* light.cookieAttenuation
		* min(shadowOutsideRamp, surface.diffuseShadowAttenuation)
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
	float3 fresnel = TomFresnelSchlick(vDotH, material.f0, _FresnelStrength);
	result.diffuse = material.albedo * TomDiffuseWeight(fresnel, material.metallic)
		* light.color * surface.toonVisibility;
	result.specular = 0.0;
	// Derivatives are evaluated outside per-pixel visibility branches.
	float toonLobe = TomStylizedGGXLobe(nDotH, material.normalVariance);
	UNITY_BRANCH
	if (_SpecularStrength > 0.0 && halfIsValid > 0.5 && surface.horizon > 0.0
		&& nDotV > 0.00001 && nDotL > 0.00001)
	{
		float3 specular = 0.0;
		UNITY_BRANCH
		if (_SpecularToonBlend < 0.999)
			specular = TomEvaluateProductionGGX(nDotV, nDotL, nDotH, vDotH,
				TomFilteredRoughness(material.roughness, material.normalVariance), material.f0, _FresnelStrength);
		float3 shaped = toonLobe * fresnel * nDotL;
		specular = lerp(specular, shaped, saturate(_SpecularToonBlend));
		float shadow = lerp(1.0, surface.artisticShadowAttenuation, saturate(_SpecularShadowStrength));
		result.specular = specular * _SpecularColor.rgb * surface.horizon
			* material.specularMask * _SpecularStrength * light.color
			* light.distanceAttenuation * light.cookieAttenuation * shadow;
	}
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

	UNITY_BRANCH
	if (_IndirectToonBlend > 0.0)
	{
		float luma = TomLuminance(irradiance);
		float tone = lerp(_IndirectShadeLevel, 1.0,
			TomSoftBand(luma, _IndirectToonThreshold, _IndirectToonSoftness));
		float3 toned = irradiance / max(luma, 0.0001) * tone * saturate(luma / 0.05);
		irradiance = lerp(irradiance, toned, saturate(_IndirectToonBlend));
	}
	float nDotV = saturate(dot(material.shadingNormalWS, viewDir));
	float3 fresnel = TomFresnelSchlick(nDotV, material.f0, _FresnelStrength);
	float3 diffuseWeight = TomDiffuseWeight(fresnel, material.metallic);
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
	float3 diffuseWeight = TomDiffuseWeight(fresnel, material.metallic);
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
	float3 fresnel = saturate(lerp(material.f0, unityFresnel, _EnvironmentFresnelStrength));
	float specularOcclusion = lerp(
		1.0,
		material.occlusion,
		saturate(_SpecularOcclusionStrength));
	float3 shaped = TomShapeEnvironment(environment);
	float3 reflected = lerp(environment * surfaceReduction, shaped, saturate(_EnvironmentToonBlend));
	return reflected * fresnel * specularOcclusion * _EnvironmentColor.rgb
		* lerp(1.0.xxx, material.albedo, saturate(_EnvironmentBaseColorTint));
}

float3 TomSampleMatCap(TomVaryings i, TomMaterialData material)
{
	float3 normalWS = material.shadingNormalWS;
	if (_MatCapNormalSource < 0.5)
		normalWS = material.geometricNormalWS;
	else if (_MatCapNormalSource < 1.5)
		normalWS = material.mainNormalWS;
	float2 uv = mul((float3x3)UNITY_MATRIX_V, normalWS).xy * 0.5 + 0.5;
	uv = uv * _MatCap_ST.xy + _MatCap_ST.zw;
	return SAMPLE_TEX2D_LOD(_MatCap, float4(uv, 0, 0), _MatCapMip).rgb;
}

float3 TomMatCapMultiplier(TomVaryings i, TomMaterialData material, float mainShadow)
{
	float3 result = 1.0;
	float mode = floor(_ReflectionMode + 0.5);
	UNITY_BRANCH
	if ((mode == 1.0 || mode == 3.0) && _MatCapIntensity > 0.0 && _MatCapBlendMode < 0.5)
	{
		float amount = saturate(material.reflectionMask * material.layerMask.b * _MatCapIntensity);
		// A material tint must be identical in Base and Add; shadow influence applies to additive layers only.
		result = lerp(1.0.xxx, TomSampleMatCap(i, material) * 2.0, amount);
	}
	return result;
}

float3 TomEnvironmentLayer(UnityGIInput giInput, TomMaterialData material, float3 viewDir, float mainShadow)
{
	float3 result = 0.0;
	float mode = floor(_ReflectionMode + 0.5);
	UNITY_BRANCH
	if ((mode == 2.0 || mode == 3.0) && _EnvironmentIntensity > 0.0)
		result = TomEvaluateProbeSpecular(giInput, material, viewDir) * material.reflectionMask
			* material.layerMask.a * _EnvironmentIntensity
			* lerp(1.0, mainShadow, saturate(_ReflectionShadowStrength));
	return result;
}

float3 TomMatCapAddLayer(TomVaryings i, TomMaterialData material, float mainShadow)
{
	float3 result = 0.0;
	float mode = floor(_ReflectionMode + 0.5);
	UNITY_BRANCH
	if ((mode == 1.0 || mode == 3.0) && _MatCapIntensity > 0.0 && _MatCapBlendMode >= 0.5)
		result = TomSampleMatCap(i, material) * material.reflectionMask * material.layerMask.b
			* _MatCapIntensity * lerp(1.0, mainShadow, saturate(_ReflectionShadowStrength));
	return result;
}

float3 TomEvaluateRim(TomMaterialData material, float3 viewDir, float3 mainLightDir, float mainShadow)
{
	float facing = saturate(dot(material.shadingNormalWS, viewDir));
	float rim = 1.0 - TomSoftBand(facing, _RimWidth, _RimSoftness);
	rim *= lerp(1.0, saturate(dot(material.geometricNormalWS, mainLightDir)), saturate(_RimLightInfluence));
	float shadow = lerp(1.0, mainShadow, saturate(_RimShadowStrength));
	return rim * _RimStrength * _RimColor.rgb * shadow * material.layerMask.g;
}

float4 TomFragBase(TomVaryings i, fixed faceSign : VFACE) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
	TomMaterialData material = TomGetBaseMaterialData(i, faceSign);
	float3 viewDir = TomSafeDirection(_WorldSpaceCameraPos.xyz - i.posWS);
	float3 lightDir = TomSafeDirection(UnityWorldSpaceLightDir(i.posWS));
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
	float3 body = (indirectDiffuse * shadowTint + vertexLightDiffuse + direct.diffuse)
		* TomMatCapMultiplier(i, material, mainSurface.artisticShadowAttenuation);
	float3 environment = TomEnvironmentLayer(giInput, material, viewDir, mainSurface.artisticShadowAttenuation);
	float3 matcap = TomMatCapAddLayer(i, material, mainSurface.artisticShadowAttenuation);
	float3 rim = TomEvaluateRim(material, viewDir, lightDir, mainSurface.artisticShadowAttenuation);
	float3 color = body + direct.specular + environment + matcap + rim + material.emission;
	int debugView = (int)floor(_DebugView + 0.5);
	if (debugView == 1) color = body;
	else if (debugView == 2) color = direct.specular;
	else if (debugView == 3) color = environment;
	else if (debugView == 4) color = _MatCapBlendMode < 0.5
		? TomMatCapMultiplier(i, material, mainSurface.artisticShadowAttenuation) : matcap;
	else if (debugView == 5) color = rim;
	else if (debugView == 6) color = material.emission;
	float4 outputColor = float4(max(color, 0.0), 1.0);
	if (debugView == 0) { UNITY_APPLY_FOG(i.fogCoord, outputColor); }
	return outputColor;
}

float4 TomFragAdd(TomVaryings i, fixed faceSign : VFACE) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
	if (_DebugView > 2.5) return 0.0;
	TomMaterialData material = TomGetDirectMaterialData(i, faceSign);
	float3 viewDir = TomSafeDirection(_WorldSpaceCameraPos.xyz - i.posWS);
	float3 lightDir = TomSafeDirection(UnityWorldSpaceLightDir(i.posWS));
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

	// Multiplicative MatCap modifies diffuse only, identically for every light.
	float3 body = direct.diffuse * TomMatCapMultiplier(i, material, 1.0);
	float3 color = body + direct.specular;
	if (_DebugView > 0.5 && _DebugView < 1.5) color = body;
	else if (_DebugView >= 1.5) color = direct.specular;
	float4 outputColor = float4(max(color, 0.0), 0.0);
	if (_DebugView < 0.5) { UNITY_APPLY_FOG(i.fogCoord, outputColor); }
	return outputColor;
}

#endif

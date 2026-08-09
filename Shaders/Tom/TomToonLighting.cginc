#ifndef TOM_TOON_LIGHTING_INC
#define TOM_TOON_LIGHTING_INC

#include "../KKPPBRBRDF.cginc"

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

struct TomLightData
{
	float3 direction;
	float3 color;
	float distanceAttenuation;
	float shadowAttenuation;
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

TomVaryings TomVert(TomVertexData v)
{
	TomVaryings o;
	o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.posCS = UnityObjectToClipPos(v.vertex);
	o.normalWS = UnityObjectToWorldNormal(v.normal);
	o.tangentWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	o.bitangentWS = normalize(cross(o.normalWS, o.tangentWS.xyz) * (v.tangent.w * unity_WorldTransformParams.w));
	o.uv0 = v.uv0;
	#define pos posCS
	TRANSFER_VERTEX_TO_FRAGMENT(o);
	#undef pos
	return o;
}

float3 TomNormalWS(TomVaryings i)
{
	float2 normalUV = i.uv0 * _NormalMap_ST.xy + _NormalMap_ST.zw;
	float2 detailUV = i.uv0 * _NormalMapDetail_ST.xy + _NormalMapDetail_ST.zw;
	float3 baseNormal = UnpackScaleNormal(SAMPLE_TEX2D(_NormalMap, normalUV), _NormalMapScale);
	float3 detailNormal = UnpackScaleNormal(SAMPLE_TEX2D_SAMPLER(_NormalMapDetail, _NormalMap, detailUV), _DetailNormalMapScale);
	float3 normalTS = BlendNormals(baseNormal, detailNormal);
	return normalize(normalTS.x * i.tangentWS.xyz + normalTS.y * i.bitangentWS + normalTS.z * i.normalWS);
}

float TomSurfaceAlpha(TomVaryings i, float mainAlpha)
{
	float2 alphaUV = i.uv0 * _AlphaMask_ST.xy + _AlphaMask_ST.zw;
	return mainAlpha * SAMPLE_TEX2D(_AlphaMask, alphaUV).r;
}

TomMaterialData TomGetMaterialData(TomVaryings i)
{
	TomMaterialData material;
	float4 mainTex = SAMPLE_TEX2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw);
	clip(TomSurfaceAlpha(i, mainTex.a) - _Cutoff);

	material.albedo = mainTex.rgb * _BaseColor.rgb;
	material.geometricNormalWS = normalize(i.normalWS);
	material.shadingNormalWS = TomNormalWS(i);

	float metallicMap = SAMPLE_TEX2D(_MetallicMap, i.uv0 * _MetallicMap_ST.xy + _MetallicMap_ST.zw).r;
	float roughnessMap = SAMPLE_TEX2D(_RoughnessMap, i.uv0 * _RoughnessMap_ST.xy + _RoughnessMap_ST.zw).r;
	float occlusionMap = SAMPLE_TEX2D(_OcclusionMap, i.uv0 * _OcclusionMap_ST.xy + _OcclusionMap_ST.zw).r;
	material.metallic = saturate(_Metallic * metallicMap);
	material.roughness = max(saturate(_Roughness * roughnessMap + _RoughnessBias), 0.04);
	material.occlusion = lerp(1.0, saturate(occlusionMap), saturate(_OcclusionStrength));

	float dielectricF0 = KKP_PBR_IorToF0(max(_SpecularIOR, 1.0));
	material.f0 = lerp(dielectricF0.xxx, material.albedo, material.metallic);
	material.specularMask = SAMPLE_TEX2D(_SpecularMask, i.uv0 * _SpecularMask_ST.xy + _SpecularMask_ST.zw).r;
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

float TomShapeShadow(float rawShadow)
{
	rawShadow = saturate(rawShadow);
	float halfSoftness = max(_ShadowSoftness, 0.001) * 0.5;
	float stylizedShadow = smoothstep(_ShadowThreshold - halfSoftness, _ShadowThreshold + halfSoftness, rawShadow);
	return lerp(rawShadow, stylizedShadow, saturate(_ShadowRemapStrength));
}

TomLightData TomBuildLightData(
	TomMaterialData material,
	float3 lightDirection,
	float3 lightColor,
	float combinedAttenuation,
	float rawShadowAttenuation,
	float intensity)
{
	TomLightData light;
	light.direction = normalize(lightDirection);
	light.color = lightColor * intensity;
	light.shadowAttenuation = TomShapeShadow(rawShadowAttenuation);
	light.diffuseShadowAttenuation = lerp(1.0, light.shadowAttenuation, saturate(_ShadowStrength));
	light.distanceAttenuation = rawShadowAttenuation > 0.0001
		? saturate(combinedAttenuation / rawShadowAttenuation)
		: saturate(combinedAttenuation);

	light.shadingNdotL = saturate(dot(material.shadingNormalWS, light.direction));
	light.geometricNdotL = saturate(dot(material.geometricNormalWS, light.direction));
	float horizonFade = max(_NormalHorizonFade, 0.001);
	float shadingHorizon = smoothstep(0.0, horizonFade, light.shadingNdotL);
	float geometricHorizon = smoothstep(0.0, horizonFade, light.geometricNdotL);
	light.horizon = shadingHorizon * geometricHorizon;

	float rampInput = light.shadingNdotL * lerp(1.0, light.diffuseShadowAttenuation, saturate(_UseRampForShadows));
	float ramp = TomSampleRamp(rampInput);
	float toonNdotL = lerp(light.shadingNdotL, ramp, saturate(_UseRamp));
	float shadowOutsideRamp = lerp(
		light.diffuseShadowAttenuation,
		1.0,
		saturate(_UseRampForShadows) * saturate(_UseRamp));
	light.toonVisibility = toonNdotL * light.distanceAttenuation * shadowOutsideRamp * light.horizon;
	return light;
}

TomLightingResult TomEvaluateDirectLight(TomMaterialData material, TomLightData light, float3 viewDir)
{
	TomLightingResult result;
	float3 halfDir = normalize(light.direction + viewDir);
	float nDotV = max(saturate(dot(material.shadingNormalWS, viewDir)), 0.0001);
	float nDotL = max(light.shadingNdotL, 0.0001);
	float nDotH = saturate(dot(material.shadingNormalWS, halfDir));
	float vDotH = saturate(dot(viewDir, halfDir));
	float ggxBlend = saturate(_GGXSpecularBlend);

	float3 fresnel = KKP_PBR_FresnelSchlick(vDotH, material.f0, _FresnelStrength);
	float3 energyConservingDiffuse = (1.0 - fresnel) * (1.0 - material.metallic);
	float3 diffuseWeight = lerp(1.0.xxx, energyConservingDiffuse, ggxBlend);
	result.diffuse = material.albedo * diffuseWeight * light.color * light.toonVisibility;

	float blinnLobe = pow(nDotH, max(_SpecularPower, 1.0)) * light.horizon;
	float3 blinnSpecular = blinnLobe * _SpecularColor.rgb;
	float3 ggxSpecular = KKP_PBR_DirectSpecularGGX(
		nDotV,
		nDotL,
		nDotH,
		vDotH,
		material.roughness,
		material.f0,
		_FresnelStrength) * nDotL * _SpecularColor.rgb * light.horizon;
	float3 specularBRDF = lerp(blinnSpecular, ggxSpecular, ggxBlend);
	float specularShadow = lerp(1.0, light.shadowAttenuation, saturate(_SpecularShadowStrength));
	result.specular = specularBRDF
		* material.specularMask
		* _SpecularStrength
		* light.color
		* light.distanceAttenuation
		* specularShadow;
	return result;
}

float3 TomEvaluateIndirectDiffuse(TomMaterialData material, float3 viewDir)
{
	float3 probeIrradiance = max(ShadeSH9(float4(material.shadingNormalWS, 1.0)), 0.0);
	float3 irradiance = lerp(_AmbientColor.rgb, probeIrradiance, saturate(_LightProbeBlend));
	float nDotV = saturate(dot(material.shadingNormalWS, viewDir));
	float3 fresnel = KKP_PBR_FresnelSchlick(nDotV, material.f0, _FresnelStrength);
	float3 energyConservingDiffuse = (1.0 - fresnel) * (1.0 - material.metallic);
	float3 diffuseWeight = lerp(1.0.xxx, energyConservingDiffuse, saturate(_GGXSpecularBlend));
	return material.albedo * diffuseWeight * irradiance * material.occlusion * _IndirectDiffuseIntensity;
}

float3 TomSampleReflectionProbes(float3 reflectionDir, float3 worldPos, float roughness)
{
	float3 probeDirection0 = reflectionDir;
#if defined(UNITY_SPECCUBE_BOX_PROJECTION)
	probeDirection0 = BoxProjectedCubemapDirection(
		reflectionDir,
		worldPos,
		unity_SpecCube0_ProbePosition,
		unity_SpecCube0_BoxMin,
		unity_SpecCube0_BoxMax);
#endif

	float mip = saturate(roughness) * UNITY_SPECCUBE_LOD_STEPS;
	float4 encodedProbe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, probeDirection0, mip);
	float3 probe0 = DecodeHDR(encodedProbe0, unity_SpecCube0_HDR);
	float3 result = probe0;

#if defined(UNITY_SPECCUBE_BLENDING)
	float blend = unity_SpecCube0_BoxMin.w;
	UNITY_BRANCH
	if (blend < 0.99999)
	{
		float3 probeDirection1 = reflectionDir;
	#if defined(UNITY_SPECCUBE_BOX_PROJECTION)
		probeDirection1 = BoxProjectedCubemapDirection(
			reflectionDir,
			worldPos,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin,
			unity_SpecCube1_BoxMax);
	#endif
		float4 encodedProbe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, probeDirection1, mip);
		float3 probe1 = DecodeHDR(encodedProbe1, unity_SpecCube1_HDR);
		result = lerp(probe1, probe0, blend);
	}
#endif
	return result;
}

float3 TomEvaluateProbeSpecular(TomVaryings i, TomMaterialData material, float3 viewDir)
{
	float roughness = lerp(
		saturate(_EnvironmentRoughness),
		material.roughness,
		saturate(_UseMaterialRoughnessForEnvironment));
	float3 reflectionDir = reflect(-viewDir, material.shadingNormalWS);
	float3 environment = TomSampleReflectionProbes(reflectionDir, i.posWS, roughness);
	float nDotV = saturate(dot(material.shadingNormalWS, viewDir));
	float3 fresnel = KKP_PBR_FresnelSchlick(nDotV, material.f0, _FresnelStrength);
	float roughness2 = roughness * roughness;
	float surfaceReduction = 1.0 / (roughness2 * roughness2 + 1.0);
	float specularOcclusion = lerp(1.0, material.occlusion, saturate(_SpecularOcclusionStrength));
	return environment * fresnel * surfaceReduction * specularOcclusion;
}

float3 TomApplyReflections(
	TomVaryings i,
	TomMaterialData material,
	float3 viewDir,
	float mainShadow,
	float3 color)
{
	float mode = floor(_ReflectionMode + 0.5);
	float useMatCap = (mode == 1.0 || mode == 3.0) ? 1.0 : 0.0;
	float useEnvironment = mode >= 2.0 ? 1.0 : 0.0;
	float reflectionShadow = lerp(1.0, mainShadow, saturate(_ReflectionShadowStrength));

	float3 normalVS = mul((float3x3)UNITY_MATRIX_V, material.shadingNormalWS);
	float2 matCapUV = normalVS.xy * 0.5 + 0.5;
	matCapUV = matCapUV * _MatCap_ST.xy + _MatCap_ST.zw;
	float3 matCap = SAMPLE_TEX2D_LOD(_MatCap, float4(matCapUV, 0, 0), _MatCapMip).rgb;
	float matCapAmount = useMatCap * material.reflectionMask * _MatCapIntensity * reflectionShadow;
	float3 matCapMultiply = color * lerp(1.0, matCap * 2.0, matCapAmount);
	float3 matCapAdd = color + matCap * matCapAmount;
	color = lerp(matCapMultiply, matCapAdd, saturate(_MatCapBlendMode));

	float3 environment = TomEvaluateProbeSpecular(i, material, viewDir);
	color += environment
		* useEnvironment
		* material.reflectionMask
		* _EnvironmentIntensity
		* reflectionShadow;
	return color;
}

float3 TomEvaluateRim(TomMaterialData material, float3 viewDir, float mainShadow)
{
	float rim = pow(saturate(1.0 - dot(material.shadingNormalWS, viewDir)), max(_RimPower, 0.01));
	float shadow = lerp(1.0, mainShadow, saturate(_RimShadowStrength));
	return rim * _RimStrength * _RimColor.rgb * shadow;
}

fixed4 TomFragBase(TomVaryings i) : SV_Target
{
	TomMaterialData material = TomGetMaterialData(i);
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS));
	float rawShadow = SHADOW_ATTENUATION(i);
	UNITY_LIGHT_ATTENUATION(combinedAttenuation, i, i.posWS);
	TomLightData mainLight = TomBuildLightData(
		material,
		lightDir,
		_LightColor0.rgb,
		combinedAttenuation,
		rawShadow,
		_MainLightIntensity);
	TomLightingResult direct = TomEvaluateDirectLight(material, mainLight, viewDir);

	float3 indirectDiffuse = TomEvaluateIndirectDiffuse(material, viewDir);
	float3 shadowTint = lerp(_ShadowColor.rgb, 1.0, mainLight.diffuseShadowAttenuation);
	float3 color = indirectDiffuse * shadowTint + direct.diffuse + direct.specular;
	color += TomEvaluateRim(material, viewDir, mainLight.shadowAttenuation);
	color = TomApplyReflections(i, material, viewDir, mainLight.shadowAttenuation, color);
	color += material.emission;
	return float4(max(color, 1E-06), 1.0);
}

fixed4 TomFragAdd(TomVaryings i) : SV_Target
{
	TomMaterialData material = TomGetMaterialData(i);
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS));
	float rawShadow = SHADOW_ATTENUATION(i);
	UNITY_LIGHT_ATTENUATION(combinedAttenuation, i, i.posWS);
	TomLightData light = TomBuildLightData(
		material,
		lightDir,
		_LightColor0.rgb,
		combinedAttenuation,
		rawShadow,
		_AdditionalLightIntensity);
	TomLightingResult direct = TomEvaluateDirectLight(material, light, viewDir);
	return float4(direct.diffuse + direct.specular, 0.0);
}

#endif

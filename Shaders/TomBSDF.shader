Shader "xukmi/TomBSDF"
{
	Properties
	{
		[Gamma]_PBRBaseColor ("PBR Base Color", Color) = (1, 1, 1, 1)
		_MainTex ("MainTex", 2D) = "white" {}

		_NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalMapScale ("Normal Map Scale", Float) = 1

		_PBRMetallic ("PBR Metallic", Range(0, 1)) = 0
		_PBRMetallicMap ("PBR Metallic Map", 2D) = "white" {}
		_PBRRoughness ("PBR Roughness", Range(0, 1)) = 0.5
		_PBRRoughnessMap ("PBR Roughness Map", 2D) = "white" {}
		_PBRRoughnessBias ("PBR Roughness Bias", Range(-1, 1)) = 0
		_PBROcclusion ("PBR Occlusion", Range(0, 1)) = 1
		_PBROcclusionMap ("PBR Occlusion Map", 2D) = "white" {}
		_PBROcclusionStrength ("PBR Occlusion Strength", Range(0, 1)) = 1

		_PBRIOR ("PBR IOR", Range(1, 2.5)) = 1.5
		_PBRSpecular ("PBR Specular", Range(0, 1)) = 0.5
		_PBRFresnelStrength ("PBR Fresnel Strength", Range(0, 2)) = 1
		_PBRDirectIntensity ("PBR Direct Light Intensity", Range(0, 4)) = 1
		_PBREnvIntensity ("PBR Environment Intensity", Range(0, 4)) = 1
		_DisablePointLights ("Disable Point Lights", Range(0, 1)) = 0

		_PBRCoatWeight ("PBR Coat Weight", Range(0, 1)) = 0
		_PBRCoatMask ("PBR Coat Mask", 2D) = "white" {}
		_PBRCoatRoughness ("PBR Coat Roughness", Range(0, 1)) = 0.15
		_PBRCoatRoughnessMap ("PBR Coat Roughness Map", 2D) = "white" {}
		_PBRCoatIOR ("PBR Coat IOR", Range(1, 2.5)) = 1.5
		_PBRCoatNormalMap ("PBR Coat Normal Map", 2D) = "bump" {}
		_PBRCoatNormalScale ("PBR Coat Normal Scale", Float) = 1

		_EmissionMask ("Emission Mask", 2D) = "black" {}
		[Gamma]_EmissionColor ("Emission Color", Color) = (0, 0, 0, 1)
		_EmissionIntensity ("Emission Intensity", Float) = 1
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		LOD 400

		Pass
		{
			Name "ForwardBase"
			Tags { "LightMode"="ForwardBase" }

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "KKPPBRBRDF.cginc"
			#include "KKPPBRInput.cginc"
			#include "KKPVertexLights.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv0 : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float3 posWS : TEXCOORD1;
				float3 normalWS : TEXCOORD2;
				float3 tangentWS : TEXCOORD3;
				float3 bitangentWS : TEXCOORD4;
				SHADOW_COORDS(5)
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normalWS = UnityObjectToWorldNormal(v.normal);
				o.tangentWS = UnityObjectToWorldDir(v.tangent.xyz);
				o.bitangentWS = cross(o.normalWS, o.tangentWS) * v.tangent.w * unity_WorldTransformParams.w;
				o.uv0 = v.uv0;
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = i.uv0;
				KKPPBRSurface surface = KKP_PBR_SampleSurface(uv, i.normalWS, i.tangentWS, i.bitangentWS);

				float3 n = surface.normalWS;
				float3 v = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
				float3 l = normalize(_WorldSpaceLightPos0.xyz - i.posWS * _WorldSpaceLightPos0.w);
				float3 h = normalize(v + l);
				float3 r = reflect(-v, n);

				float nDotL = saturate(dot(n, l));
				float nDotV = saturate(dot(n, v));
				float nDotH = saturate(dot(n, h));
				float vDotH = saturate(dot(v, h));

				float dielectricF0 = KKP_PBR_IorToF0(_PBRIOR) * _PBRSpecular * 2.0;
				float3 f0 = lerp(dielectricF0.xxx, surface.albedo, surface.metallic);
				float3 f = KKP_PBR_FresnelSchlick(vDotH, f0, _PBRFresnelStrength);
				float3 specularBRDF = KKP_PBR_DirectSpecularGGX(nDotV, nDotL, nDotH, vDotH, surface.roughness, f0, _PBRFresnelStrength);

				float3 kd = (1.0 - f) * (1.0 - surface.metallic);
				float atten = LIGHT_ATTENUATION(i);
				float3 directLight = _LightColor0.rgb * atten * nDotL * _PBRDirectIntensity;
				float3 directDiffuse = kd * surface.albedo / KKP_PBR_PI * directLight;
				float3 directSpecular = specularBRDF * directLight;

				float3 coatN = surface.coatNormalWS;
				float coatNDotL = saturate(dot(coatN, l));
				float coatNDotV = saturate(dot(coatN, v));
				float coatNDotH = saturate(dot(coatN, h));
				float3 coatF0 = KKP_PBR_IorToF0(_PBRCoatIOR).xxx;

				KKVertexLight vertexLights[4];
				GetVertexLightsTwo(vertexLights, i.posWS, _DisablePointLights);

				float3 vertexDiffuse = 0.0;
				float3 vertexSpecular = 0.0;
				float3 vertexCoat = 0.0;
				[unroll]
				for (int lightIndex = 0; lightIndex < 4; lightIndex++)
				{
					KKVertexLight vertexLight = vertexLights[lightIndex];
					float3 pointL = vertexLight.dir;
					float3 pointH = normalize(v + pointL);

					float pointNDotL = saturate(dot(n, pointL));
					float pointNDotH = saturate(dot(n, pointH));
					float pointVDotH = saturate(dot(v, pointH));
					float3 pointLight = vertexLight.col.rgb * vertexLight.atten * pointNDotL * _PBRDirectIntensity;
					float3 pointF = KKP_PBR_FresnelSchlick(pointVDotH, f0, _PBRFresnelStrength);
					float3 pointKd = (1.0 - pointF) * (1.0 - surface.metallic);

					vertexDiffuse += pointKd * surface.albedo / KKP_PBR_PI * pointLight;
					vertexSpecular += KKP_PBR_DirectSpecularGGX(nDotV, pointNDotL, pointNDotH, pointVDotH, surface.roughness, f0, _PBRFresnelStrength) * pointLight;

					float coatPointNDotL = saturate(dot(coatN, pointL));
					float coatPointNDotH = saturate(dot(coatN, pointH));
					float3 coatPointLight = vertexLight.col.rgb * vertexLight.atten * coatPointNDotL * surface.coatWeight * _PBRDirectIntensity;
					vertexCoat += KKP_PBR_DirectSpecularGGX(coatNDotV, coatPointNDotL, coatPointNDotH, pointVDotH, surface.coatRoughness, coatF0, _PBRFresnelStrength) * coatPointLight;
				}

				directDiffuse += vertexDiffuse;
				directSpecular += vertexSpecular;

				float3 ambientDiffuse = ShadeSH9(float4(n, 1.0)).rgb * surface.albedo * kd * surface.occlusion;
				float3 envSpecular = KKP_PBR_SampleReflectionProbe(r, surface.roughness) * KKP_PBR_FresnelSchlick(nDotV, f0, _PBRFresnelStrength) * surface.occlusion * _PBREnvIntensity;

				float3 coatDirect = KKP_PBR_DirectSpecularGGX(coatNDotV, coatNDotL, coatNDotH, vDotH, surface.coatRoughness, coatF0, _PBRFresnelStrength);
				coatDirect *= _LightColor0.rgb * atten * coatNDotL * surface.coatWeight * _PBRDirectIntensity;
				coatDirect += vertexCoat;
				float3 coatEnv = KKP_PBR_SampleReflectionProbe(reflect(-v, coatN), surface.coatRoughness) * KKP_PBR_FresnelSchlick(coatNDotV, coatF0, _PBRFresnelStrength) * surface.coatWeight * surface.occlusion * _PBREnvIntensity;

				float3 finalCol = directDiffuse + ambientDiffuse;
				finalCol += directSpecular;
				finalCol += envSpecular;
				finalCol += coatDirect + coatEnv;
				finalCol += surface.emission;

				return float4(max(finalCol, 1E-06), 1.0);
			}
			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f
			{
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}

	Fallback "Standard"
}

Shader "xukmi/TomNormalOnlyOverlay"
{
	Properties
	{
		_OverlayNormalMap ("Overlay Normal Map", 2D) = "bump" {}
		_OverlayMask ("Overlay Mask", 2D) = "white" {}
		_OverlayMatCap ("Overlay MatCap", 2D) = "black" {}

		_OverlayNormalScale ("Overlay Normal Scale", Range(0, 4)) = 1
		_OverlayAlpha ("Overlay Alpha", Range(0, 4)) = 1
		_OverlayTint ("Overlay Tint", Color) = (1, 1, 1, 1)
		_MaskStrength ("Mask Strength", Range(0, 1)) = 1
		_SlopeIntensity ("Normal Slope Intensity", Range(0, 4)) = 0.6
		_SlopeAlpha ("Normal Slope Alpha", Range(0, 4)) = 0.5
		_SlopeThreshold ("Normal Slope Threshold", Range(0, 1)) = 0.3
		_SlopeContrast ("Normal Slope Contrast", Range(0.1, 8)) = 4
		_NormalZThreshold ("Normal Z Threshold", Range(0, 1)) = 0.02
		_NormalZContrast ("Normal Z Contrast", Range(0.1, 32)) = 12
		_FacingBoostIntensity ("Facing Boost Intensity", Range(0, 4)) = 1.6
		_FacingBoostAlpha ("Facing Boost Alpha", Range(0, 4)) = 0.6
		_FacingBoostPower ("Facing Boost Power", Range(0.1, 16)) = 12

		_Roughness ("GGX Roughness", Range(0.02, 1)) = 0.22
		_IOR ("GGX IOR", Range(1, 2.5)) = 1.333
		_FresnelStrength ("Fresnel Strength", Range(0, 4)) = 1
		_GGXIntensity ("GGX Intensity", Range(0, 8)) = 0.5
		_GGXAlpha ("GGX Alpha", Range(0, 8)) = 0.5
		_DirectIntensity ("Direct Light Intensity", Range(0, 8)) = 1
		_PointLightIntensity ("Point Light Intensity", Range(0, 8)) = 1
		_DisablePointLights ("Disable Point Lights", Range(0, 1)) = 0

		[Gamma]_FakeSpecColor ("Fake Specular Color", Color) = (1, 1, 1, 1)
		_FakeSpecIntensity ("Fake Specular Intensity", Range(0, 8)) = 1
		_FakeSpecPower ("Fake Specular Power", Range(1, 256)) = 100
		_FakeSpecWrap ("Fake Specular Wrap", Range(0, 1)) = 0.35
		_FakeSpecAlpha ("Fake Specular Alpha", Range(0, 8)) = 1

		_MatCapIntensity ("MatCap Intensity", Range(0, 8)) = 1
		_MatCapAlpha ("MatCap Alpha", Range(0, 8)) = 1
		_MatCapFrontStrength ("MatCap Front Strength", Range(0, 2)) = 0.75
		_MatCapAlphaThreshold ("MatCap Alpha Threshold", Range(0, 1)) = 0.45
		_MatCapAlphaContrast ("MatCap Alpha Contrast", Range(0.1, 8)) = 3
		_MatCapBlur ("MatCap Blur", Range(0, 1)) = 0
		_MatCapBlurMip ("MatCap Blur Mip", Range(0, 8)) = 4
		_ReflectRotation ("MatCap Rotation", Range(0, 360)) = 0

		[MaterialToggle] _AdjustBackfaceNormals ("Adjust Backface Normals", Float) = 0
		[Enum(Off,0,On,1)] _ZWrite ("ZWrite", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Src", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Dst", Float) = 1
		[Enum(Off,0,Front,1,Back,2)] _CullOption ("Cull Option", Range(0, 2)) = 2
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent+60" }
		LOD 300

		Pass
		{
			Name "ForwardBase"
			Tags { "LightMode"="ForwardBase" "Queue"="Transparent+60" "RenderType"="Transparent" }
			Blend [_BlendSrc] [_BlendDst], [_BlendSrc] [_BlendDst]
			ZWrite [_ZWrite]
			ZTest LEqual
			Cull [_CullOption]
			Offset -1, -1

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "KKPPBRBRDF.cginc"
			#include "KKPVertexLights.cginc"

			sampler2D _OverlayNormalMap;
			float4 _OverlayNormalMap_ST;
			sampler2D _OverlayMask;
			float4 _OverlayMask_ST;
			sampler2D _OverlayMatCap;
			float4 _OverlayMatCap_ST;

			float _OverlayNormalScale;
			float _OverlayAlpha;
			float4 _OverlayTint;
			float _MaskStrength;
			float _SlopeIntensity;
			float _SlopeAlpha;
			float _SlopeThreshold;
			float _SlopeContrast;
			float _NormalZThreshold;
			float _NormalZContrast;
			float _FacingBoostIntensity;
			float _FacingBoostAlpha;
			float _FacingBoostPower;

			float _Roughness;
			float _IOR;
			float _FresnelStrength;
			float _GGXIntensity;
			float _GGXAlpha;
			float _DirectIntensity;
			float _PointLightIntensity;
			float _DisablePointLights;

			float4 _FakeSpecColor;
			float _FakeSpecIntensity;
			float _FakeSpecPower;
			float _FakeSpecWrap;
			float _FakeSpecAlpha;

			float _MatCapIntensity;
			float _MatCapAlpha;
			float _MatCapFrontStrength;
			float _MatCapAlphaThreshold;
			float _MatCapAlphaContrast;
			float _MatCapBlur;
			float _MatCapBlurMip;
			float _ReflectRotation;
			float _AdjustBackfaceNormals;

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
				float4 tanWS : TEXCOORD3;
				SHADOW_COORDS(4)
			};

			float2 rotateUV(float2 uv, float2 pivot, float rotation)
			{
				float cosa = cos(rotation);
				float sina = sin(rotation);
				uv -= pivot;
				return float2(
					cosa * uv.x - sina * uv.y,
					cosa * uv.y + sina * uv.x
				) + pivot;
			}

			float Luminance(float3 col)
			{
				return dot(col, float3(0.299, 0.587, 0.114));
			}

			float ThresholdContrast(float value, float threshold, float contrast)
			{
				return saturate((value - threshold) * contrast);
			}

			float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign)
			{
				return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
			}

			v2f vert(appdata v)
			{
				v2f o;
				o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normalWS = UnityObjectToWorldNormal(v.normal);
				o.tanWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				o.uv0 = v.uv0;
				TRANSFER_SHADOW(o);
				return o;
			}

			float3 GetOverlayNormalTS(v2f i)
			{
				float2 normalUV = i.uv0 * _OverlayNormalMap_ST.xy + _OverlayNormalMap_ST.zw;
				float4 packedNormal = tex2D(_OverlayNormalMap, normalUV);
				return UnpackScaleNormal(packedNormal, _OverlayNormalScale);
			}

			float3 GetOverlayNormalWS(v2f i, float3 normalTS, int faceDir)
			{
				float3 binormal = CreateBinormal(i.normalWS, i.tanWS.xyz, i.tanWS.w);
				float3 normal = normalize(
					normalTS.x * i.tanWS.xyz +
					normalTS.y * binormal +
					normalTS.z * i.normalWS
				);

				int adjust = int(floor(_AdjustBackfaceNormals));
				return adjust ? normal * (faceDir <= 0 ? -1 : 1) : normal;
			}

			float3 SampleOverlayMatCap(float3 normalWS)
			{
				float3 viewNormal = mul((float3x3)UNITY_MATRIX_V, normalWS);
				float2 uv = viewNormal.xy * 0.5 * _OverlayMatCap_ST.xy + 0.5 + _OverlayMatCap_ST.zw;
				uv = rotateUV(uv, float2(0.5, 0.5), radians(_ReflectRotation));

				if (_MatCapBlur <= 0.0001)
					return tex2D(_OverlayMatCap, uv).rgb;

				float mip = _MatCapBlur * _MatCapBlurMip;
				return tex2Dlod(_OverlayMatCap, float4(uv, 0, mip)).rgb;
			}

			float3 EvaluateGGX(v2f i, float3 n, float3 v, float3 l, float3 lightColor, float attenuation)
			{
				float3 h = normalize(v + l);
				float nDotL = saturate(dot(n, l));
				float nDotV = saturate(dot(n, v));
				float nDotH = saturate(dot(n, h));
				float vDotH = saturate(dot(v, h));
				float3 f0 = KKP_PBR_IorToF0(_IOR).xxx;
				float3 brdf = KKP_PBR_DirectSpecularGGX(nDotV, nDotL, nDotH, vDotH, _Roughness, f0, _FresnelStrength);
				return brdf * lightColor * attenuation * nDotL;
			}

			float GetNormalOnlyMask(float3 normalTS)
			{
				float normalSlope = saturate(length(normalTS.xy));
				float slopeMask = ThresholdContrast(pow(normalSlope, 0.75), _SlopeThreshold, _SlopeContrast);
				float zMask = ThresholdContrast(1.0 - saturate(normalTS.z), _NormalZThreshold, _NormalZContrast);
				return saturate(max(slopeMask, zMask));
			}

			fixed4 frag(v2f i, int faceDir : VFACE) : SV_Target
			{
				float2 maskUV = i.uv0 * _OverlayMask_ST.xy + _OverlayMask_ST.zw;
				float mask = tex2D(_OverlayMask, maskUV).r;
				mask = lerp(1.0, mask, _MaskStrength);

				float3 normalTS = GetOverlayNormalTS(i);
				float normalMask = GetNormalOnlyMask(normalTS);
				float3 n = GetOverlayNormalWS(i, normalTS, faceDir);
				float3 v = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
				float3 l = normalize(_WorldSpaceLightPos0.xyz - i.posWS * _WorldSpaceLightPos0.w);
				float3 h = normalize(v + l);
				float facing = pow(saturate(dot(normalize(i.normalWS), v)), _FacingBoostPower);

				float atten = LIGHT_ATTENUATION(i);
				float3 ggx = EvaluateGGX(i, n, v, l, _LightColor0.rgb, atten) * _GGXIntensity * _DirectIntensity * normalMask;

			#ifdef VERTEXLIGHT_ON
				KKVertexLight vertexLights[4];
				GetVertexLightsTwo(vertexLights, i.posWS, _DisablePointLights);
				[unroll]
				for (int lightIndex = 0; lightIndex < 4; lightIndex++)
				{
					KKVertexLight vertexLight = vertexLights[lightIndex];
					ggx += EvaluateGGX(i, n, v, vertexLight.dir, vertexLight.col.rgb, vertexLight.atten) * _GGXIntensity * _PointLightIntensity * normalMask;
				}
			#endif

				float wrappedNdotH = saturate(dot(n, h) * 0.5 + 0.5);
				float fakeSpec = pow(lerp(saturate(dot(n, h)), wrappedNdotH, _FakeSpecWrap), _FakeSpecPower) * normalMask;
				float3 fakeCol = fakeSpec * _FakeSpecColor.rgb * _FakeSpecIntensity;

				float3 matcap = SampleOverlayMatCap(n);
				matcap = pow(max(matcap, 1E-06), 0.454545) * _MatCapIntensity * normalMask;
				float matcapAlpha = ThresholdContrast(Luminance(matcap), _MatCapAlphaThreshold, _MatCapAlphaContrast) * _MatCapAlpha * normalMask;

				float fresnel = pow(1.0 - saturate(dot(n, v)), 5.0) * _FresnelStrength;
				float3 slopeCol = normalMask * _FakeSpecColor.rgb * _SlopeIntensity;
				float3 facingCol = normalMask * facing * _FakeSpecColor.rgb * _FacingBoostIntensity;
				float3 finalCol = (ggx + fakeCol + slopeCol + facingCol + matcap * (_MatCapFrontStrength + fresnel)) * _OverlayTint.rgb;

				float alphaSource = Luminance(ggx) * _GGXAlpha + fakeSpec * _FakeSpecAlpha + normalMask * _SlopeAlpha + normalMask * facing * _FacingBoostAlpha + matcapAlpha;
				float alpha = saturate(alphaSource * _OverlayAlpha * mask * _OverlayTint.a * normalMask);

				return float4(max(finalCol, 0.0), alpha);
			}
			ENDCG
		}
	}

	Fallback Off
}

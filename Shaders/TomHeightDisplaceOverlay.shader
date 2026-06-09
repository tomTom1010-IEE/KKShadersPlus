Shader "xukmi/TomHeightDisplaceOverlay"
{
	Properties
	{
		_HeightMap ("Height / Bump Map", 2D) = "black" {}
		_OverlayMask ("Overlay Mask", 2D) = "white" {}
		_OverlayMatCap ("Overlay MatCap", 2D) = "black" {}

		_HeightScale ("Height Normal Scale", Range(0, 16)) = 4
		_HeightThreshold ("Height Threshold", Range(0, 1)) = 0.08
		_HeightContrast ("Height Contrast", Range(0.1, 32)) = 8
		[MaterialToggle] _IsHeightReverse ("Is Height Reverse", Float) = 0
		_DisplaceStrength ("Displace Strength", Range(-1, 1)) = 0.02
		_OverlayAlpha ("Overlay Alpha", Range(0, 4)) = 1
		_OverlayTint ("Overlay Tint", Color) = (1, 1, 1, 1)
		_MaskStrength ("Mask Strength", Range(0, 1)) = 1

		_TessTex ("Tess Tex", 2D) = "white" {}
		_TessMax ("Tess Max", Range(1, 25)) = 8
		_TessMin ("Tess Min", Range(1, 25)) = 1
		_TessBias ("Tess Distance Bias", Range(1, 100)) = 75
		_TessSmooth ("Tess Smooth", Range(0, 1)) = 0

		[Gamma]_SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
		_SpecularIntensity ("Specular Intensity", Range(0, 8)) = 1
		_SpecularPower ("Specular Power", Range(0, 1)) = 0.2
		_SpecularWrap ("Specular Wrap", Range(0, 1)) = 0.25
		_SpecularAlpha ("Specular Alpha", Range(0, 8)) = 1
		_DirectIntensity ("Direct Light Intensity", Range(0, 8)) = 1
		_PointLightIntensity ("Point Light Intensity", Range(0, 8)) = 1
		_DisablePointLights ("Disable Point Lights", Range(0, 1)) = 0

		[Gamma]_RimColor ("Rim Color", Color) = (1, 1, 1, 1)
		_RimPower ("Rim Power", Range(0.1, 16)) = 3
		_RimIntensity ("Rim Intensity", Range(0, 8)) = 1
		_RimAlpha ("Rim Alpha", Range(0, 8)) = 1
		_RimUseHeightNormal ("Rim Use Height Normal", Range(0, 1)) = 0

		_MatCapIntensity ("MatCap Intensity", Range(0, 8)) = 1
		_MatCapAlpha ("MatCap Alpha", Range(0, 8)) = 1
		_MatCapAlphaThreshold ("MatCap Alpha Threshold", Range(0, 1)) = 0.35
		_MatCapAlphaContrast ("MatCap Alpha Contrast", Range(0.1, 8)) = 3
		_MatCapMulOrAdd ("MatCap Mul Or Add", Range(0, 1)) = 1
		_MatCapBlend ("MatCap Blend", Range(0, 1)) = 1
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
		LOD 400

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
			#pragma target 5.0
			#pragma vertex vert
			#pragma hull hull
			#pragma domain domain
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma only_renderers d3d11 glcore metal xboxone ps4

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "KKPVertexLights.cginc"

			sampler2D _HeightMap;
			sampler2D _OverlayMask;
			sampler2D _OverlayMatCap;
			sampler2D _TessTex;
			float4 _HeightMap_ST;
			float4 _HeightMap_TexelSize;
			float4 _OverlayMask_ST;
			float4 _OverlayMatCap_ST;

			float _HeightScale;
			float _HeightThreshold;
			float _HeightContrast;
			float _IsHeightReverse;
			float _DisplaceStrength;
			float _OverlayAlpha;
			float4 _OverlayTint;
			float _MaskStrength;

			float _TessMax;
			float _TessMin;
			float _TessBias;
			float _TessSmooth;

			float4 _SpecularColor;
			float _SpecularIntensity;
			float _SpecularPower;
			float _SpecularWrap;
			float _SpecularAlpha;
			float _DirectIntensity;
			float _PointLightIntensity;
			float _DisablePointLights;

			float4 _RimColor;
			float _RimPower;
			float _RimIntensity;
			float _RimAlpha;
			float _RimUseHeightNormal;

			float _MatCapIntensity;
			float _MatCapAlpha;
			float _MatCapAlphaThreshold;
			float _MatCapAlphaContrast;
			float _MatCapMulOrAdd;
			float _MatCapBlend;
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

			struct controlpoint
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv0 : TEXCOORD0;
				float3 posWS : TEXCOORD1;
			};

			struct tessfactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
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

			float Luminance(float3 col)
			{
				return dot(col, float3(0.299, 0.587, 0.114));
			}

			float ThresholdContrast(float value, float threshold, float contrast)
			{
				return saturate((value - threshold) * contrast);
			}

			float SampleHeightRawLOD(float2 uv, float2 offset)
			{
				return tex2Dlod(_HeightMap, float4(uv + offset * _HeightMap_TexelSize.xy, 0, 0)).r;
			}

			float SampleHeightRaw(float2 uv, float2 offset)
			{
				return tex2D(_HeightMap, uv + offset * _HeightMap_TexelSize.xy).r;
			}

			float ApplyHeightReverse(float height)
			{
				return lerp(height, 1.0 - height, saturate(_IsHeightReverse));
			}

			float SampleHeightLOD(float2 uv, float2 offset)
			{
				return ApplyHeightReverse(SampleHeightRawLOD(uv, offset));
			}

			float SampleHeight(float2 uv, float2 offset)
			{
				return ApplyHeightReverse(SampleHeightRaw(uv, offset));
			}

			float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign)
			{
				return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
			}

			float2 rotateUV(float2 uv, float2 pivot, float rotation)
			{
				float cosa = cos(rotation);
				float sina = sin(rotation);
				uv -= pivot;
				return float2(cosa * uv.x - sina * uv.y, cosa * uv.y + sina * uv.x) + pivot;
			}

			controlpoint vert(appdata v)
			{
				controlpoint o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				o.tangent = v.tangent;
				o.uv0 = v.uv0;
				o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			float EdgeFactor(controlpoint a, controlpoint b)
			{
				float dist = distance(_WorldSpaceCameraPos, (a.posWS + b.posWS) * 0.5);
				float len = distance(a.posWS, b.posWS) * _TessBias * 3.0;
				float tessTex = tex2Dlod(_TessTex, float4((a.uv0 + b.uv0) * 0.5, 0, 0)).r;
				return max(_TessMin, min(_TessMax, len / max(dist * dist, 0.001)) * tessTex);
			}

			tessfactors patchFunc(InputPatch<controlpoint, 3> patch)
			{
				tessfactors f;
				f.edge[0] = EdgeFactor(patch[1], patch[2]);
				f.edge[1] = EdgeFactor(patch[2], patch[0]);
				f.edge[2] = EdgeFactor(patch[0], patch[1]);
				f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) / 3.0;
				return f;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[outputcontrolpoints(3)]
			[patchconstantfunc("patchFunc")]
			controlpoint hull(InputPatch<controlpoint, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			v2f BuildVaryings(appdata v)
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

			[domain("tri")]
			v2f domain(tessfactors factors, OutputPatch<controlpoint, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata v;
				v.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				v.normal = normalize(patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z);
				float4 tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				v.tangent = float4(normalize(tangent.xyz), tangent.w >= 0 ? 1 : -1);
				v.uv0 = patch[0].uv0 * bary.x + patch[1].uv0 * bary.y + patch[2].uv0 * bary.z;

				float2 heightUV = v.uv0 * _HeightMap_ST.xy + _HeightMap_ST.zw;
				float height = SampleHeightLOD(heightUV, float2(0, 0));
				float waterMask = ThresholdContrast(height, _HeightThreshold, _HeightContrast);
				v.vertex.xyz += v.normal * height * waterMask * _DisplaceStrength;
				return BuildVaryings(v);
			}

			float3 GetHeightNormalTS(float2 uv)
			{
				float hL = SampleHeight(uv, float2(-1, 0));
				float hR = SampleHeight(uv, float2(1, 0));
				float hD = SampleHeight(uv, float2(0, -1));
				float hU = SampleHeight(uv, float2(0, 1));
				float2 grad = float2(hR - hL, hU - hD) * _HeightScale;
				return normalize(float3(-grad.x, -grad.y, 1.0));
			}

			float3 NormalTS2WS(v2f i, float3 normalTS, int faceDir)
			{
				float3 binormal = CreateBinormal(i.normalWS, i.tanWS.xyz, i.tanWS.w);
				float3 normal = normalize(normalTS.x * i.tanWS.xyz + normalTS.y * binormal + normalTS.z * i.normalWS);
				return int(floor(_AdjustBackfaceNormals)) ? normal * (faceDir <= 0 ? -1 : 1) : normal;
			}

			float3 SampleMatCap(float3 normalWS)
			{
				float3 viewNormal = mul((float3x3)UNITY_MATRIX_V, normalWS);
				float2 uv = viewNormal.xy * 0.5 * _OverlayMatCap_ST.xy + 0.5 + _OverlayMatCap_ST.zw;
				uv = rotateUV(uv, float2(0.5, 0.5), radians(_ReflectRotation));
				if (_MatCapBlur <= 0.0001)
					return tex2D(_OverlayMatCap, uv).rgb;
				return tex2Dlod(_OverlayMatCap, float4(uv, 0, _MatCapBlur * _MatCapBlurMip)).rgb;
			}

			float EvaluateSpecular(float3 n, float3 v, float3 l)
			{
				float3 h = normalize(v + l);
				float ndoth = saturate(dot(n, h));
				float wrapped = saturate(dot(n, h) * 0.5 + 0.5);
				float specTerm = max(lerp(ndoth, wrapped, _SpecularWrap), 1E-06);
				float specPower = _SpecularPower * 256.0;
				return saturate(pow(specTerm, specPower) * _SpecularPower * _SpecularColor.a);
			}

			float EvaluateRim(float3 geometryNormalWS, float3 heightNormalWS, float3 viewDir)
			{
				float3 rimNormal = normalize(lerp(normalize(geometryNormalWS), normalize(heightNormalWS), _RimUseHeightNormal));
				return pow(1.0 - saturate(dot(rimNormal, viewDir)), _RimPower) * _RimIntensity;
			}

			float3 ApplyMatCapBlend(float3 baseCol, float3 matcapCol)
			{
				float3 matcap = saturate(matcapCol);
				float3 mulCol = baseCol * matcap;
				float3 addCol = baseCol + matcapCol;
				return lerp(baseCol, lerp(mulCol, addCol, _MatCapMulOrAdd), _MatCapBlend);
			}

			float4 GetHeightColorOverlay(float height, float waterMask)
			{
				return float4(0, 0, 0, 0);
			}

			fixed4 frag(v2f i, int faceDir : VFACE) : SV_Target
			{
				float2 heightUV = i.uv0 * _HeightMap_ST.xy + _HeightMap_ST.zw;
				float height = SampleHeight(heightUV, float2(0, 0));
				float waterMask = ThresholdContrast(height, _HeightThreshold, _HeightContrast);
				float mask = lerp(1.0, tex2D(_OverlayMask, i.uv0 * _OverlayMask_ST.xy + _OverlayMask_ST.zw).r, _MaskStrength);

				float3 n = NormalTS2WS(i, GetHeightNormalTS(heightUV), faceDir);
				float3 v = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
				float3 l = normalize(_WorldSpaceLightPos0.xyz - i.posWS * _WorldSpaceLightPos0.w);

				float spec = EvaluateSpecular(n, v, l) * _DirectIntensity * LIGHT_ATTENUATION(i);
			#ifdef VERTEXLIGHT_ON
				KKVertexLight vertexLights[4];
				GetVertexLightsTwo(vertexLights, i.posWS, _DisablePointLights);
				[unroll]
				for (int lightIndex = 0; lightIndex < 4; lightIndex++)
					spec += EvaluateSpecular(n, v, vertexLights[lightIndex].dir) * vertexLights[lightIndex].atten * _PointLightIntensity;
			#endif

				spec *= waterMask;
				float3 specCol = spec * _SpecularColor.rgb * _SpecularIntensity;
				float rim = EvaluateRim(i.normalWS, n, v) * waterMask;
				float3 rimCol = rim * _RimColor.rgb;
				float4 heightColorOverlay = GetHeightColorOverlay(height, waterMask);
				float3 matcap = pow(max(SampleMatCap(n), 1E-06), 0.454545) * _MatCapIntensity * waterMask;
				float matcapAlpha = ThresholdContrast(Luminance(matcap), _MatCapAlphaThreshold, _MatCapAlphaContrast) * _MatCapAlpha;
				float3 baseCol = (specCol + rimCol + heightColorOverlay.rgb) * _OverlayTint.rgb;
				float3 finalCol = ApplyMatCapBlend(baseCol, matcap * _OverlayTint.rgb);
				float alpha = saturate((spec * _SpecularAlpha + rim * _RimAlpha + matcapAlpha + heightColorOverlay.a) * _OverlayAlpha * mask * _OverlayTint.a);
				return float4(max(finalCol, 0.0), alpha);
			}
			ENDCG
		}
	}
	Fallback Off
}

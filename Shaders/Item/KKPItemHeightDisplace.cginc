#ifndef KKP_ITEM_HEIGHT_DISPLACE_INCLUDED
#define KKP_ITEM_HEIGHT_DISPLACE_INCLUDED

#include "KKPItemHeightCore.cginc"

float _HeightDisplaceStrength;
float _HeightDisplaceNormalStrength;

void HeightDisplacementValues(VertexData v, inout float4 vertex, inout float3 normal)
{
	float height = KKPSampleHeightUVLOD(KKPHeightUV(v.uv0));
	float heightMask = KKPHeightMaskFromValue(height);
	float displacement = height * heightMask * _HeightDisplaceStrength;
	vertex.xyz += normal * displacement;

	float3 heightNormal = KKPHeightNormalTSLOD(v.uv0, _HeightScale * _HeightDisplaceNormalStrength);
	float3 tangent = normalize(v.tangent.xyz);
	float3 binormal = normalize(cross(normal, tangent) * v.tangent.w);
	float3 objectHeightNormal = normalize(mul(heightNormal, float3x3(tangent, binormal, normal)));
	normal = normalize(lerp(normal, objectHeightNormal, saturate(_HeightDisplaceNormalStrength)));
}

#endif

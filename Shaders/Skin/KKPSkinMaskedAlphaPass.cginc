#ifndef KKP_SKIN_MASKED_ALPHA_PASS_INC
#define KKP_SKIN_MASKED_ALPHA_PASS_INC

// Shared by both visible passes and by a future optional front depth prepass.
Varyings SkinMaskedAlphaVert(VertexData v)
{
	Varyings o;
	UNITY_INITIALIZE_OUTPUT(Varyings, o);
	o.posWS = mul(unity_ObjectToWorld, v.vertex);
	o.posCS = mul(UNITY_MATRIX_VP, o.posWS);
	o.normalWS = UnityObjectToWorldNormal(v.normal);
	o.tanWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	float3 biTan = cross(o.tanWS.xyz, o.normalWS);
	o.bitanWS = normalize(biTan);
	o.color = v.color;
	o.uv0 = v.uv0;
	o.uv1 = v.uv1;
	o.uv2 = v.uv2;
	o.uv3 = v.uv3;

#ifdef SHADOWS_SCREEN
	float4 projPos = o.posCS;
	projPos.y *= _ProjectionParams.x;
	float4 projbiTan;
	projbiTan.xyz = biTan;
	projbiTan.xzw = projPos.xwy * 0.5;
	o.shadowCoordinate.zw = projPos.zw;
	o.shadowCoordinate.xy = projbiTan.zz + projbiTan.xw;
#endif
	return o;
}

#endif

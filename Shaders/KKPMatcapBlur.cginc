#ifndef KKP_MATCAPBLUR_INC
#define KKP_MATCAPBLUR_INC

float2 KKP_GetMatcapUV_Blur(float3 normal)
{
    float3 viewNormal = mul((float3x3)UNITY_MATRIX_V, normal);
    float2 uv = viewNormal.xy * 0.5 * _ReflectionMapCap_ST.xy + 0.5 + _ReflectionMapCap_ST.zw;
    uv = rotateUV(uv, float2(0.5, 0.5), radians(_ReflectRotation));
    return uv;
}

float4 KKP_GetMatcapSampleBlur(float3 normal, float3 posWS)
{
    float2 uv = KKP_GetMatcapUV_Blur(normal);

    if (_UseMatCapBlur <= 0.5 || _MatCapBlur <= 0.0001)
    {
        return SAMPLE_TEX2D(_ReflectionMapCap, uv);
    }
    else
    {
        float mip = _MatCapBlur * _MatCapBlurMip;
        return SAMPLE_TEX2D_LOD(_ReflectionMapCap, float4(uv, 0, 0), mip);
    }
}

#endif
// Copyright Epic Games, Inc. All Rights Reserved.


#include "./Resources/SkyAtmosphereCommon.hlsl"

// Cloud shader code is a shame but it does what it needs to in the end.

Texture3D<float4> CloudTexture : register(t0);
SamplerState g_LinearSampler : register(s0);

struct CloudVertexOutput
{
    float4 position : SV_POSITION;
    float3 worldPos : TEXCOORD0;
};

static const float3 cubeVertices[36] =
{
    // Front
    float3(-1, -1, 1), float3(-1, 1, 1), float3(1, 1, 1),
    float3(-1, -1, 1), float3(1, 1, 1), float3(1, -1, 1),

    // Back
    float3(1, -1, -1), float3(1, 1, -1), float3(-1, 1, -1),
    float3(1, -1, -1), float3(-1, 1, -1), float3(-1, -1, -1),

    // Left
    float3(-1, -1, -1), float3(-1, 1, -1), float3(-1, 1, 1),
    float3(-1, -1, -1), float3(-1, 1, 1), float3(-1, -1, 1),

    // Right
    float3(1, -1, 1), float3(1, 1, 1), float3(1, 1, -1),
    float3(1, -1, 1), float3(1, 1, -1), float3(1, -1, -1),

    // Top
    float3(-1, 1, 1), float3(-1, 1, -1), float3(1, 1, -1),
    float3(-1, 1, 1), float3(1, 1, -1), float3(1, 1, 1),

    // Bottom
    float3(-1, -1, -1), float3(-1, -1, 1), float3(1, -1, 1),
    float3(-1, -1, -1), float3(1, -1, 1), float3(1, -1, -1),
};

float3 cubeHeight = float3(0, 10, 100);

CloudVertexOutput CloudVertexShader(
    uint vertexId : SV_VertexID,
    uint instanceId : SV_InstanceID)
{
    CloudVertexOutput output;

    // Use same offset as terrain to ensure cloud is in view
    float4 worldPos = float4(cubeVertices[vertexId], 1.0f);
    output.worldPos = worldPos.xyz;
    output.position = mul(gViewProjMat, worldPos);

    return output;
}


float3 shpere_center = float3(0, 0, 0);
float radius = 0.5;



float4 CloudPixelShader(CloudVertexOutput input) : SV_TARGET
{
    float3 ray_direct = normalize(input.worldPos - camera);
    float3 rayOrigin = camera;
    float step_size = 0.05;
    
    float totalDensity = 0.0;
    
    for (int i = 0; i < 200; i++)
    {
        rayOrigin += (ray_direct * step_size);
        
        float3 uvw = rayOrigin * 0.5 + 0.5;
        
        if (all(uvw >= 0.0) && all(uvw <= 1.0))
        {
            float sampleValue = CloudTexture.SampleLevel(g_LinearSampler, uvw, 0).r;
            totalDensity += sampleValue * 0.01;
        }
        else if (totalDensity > 0.0)
        {
            break;
        }
    }
    totalDensity = saturate(totalDensity);
    float3 color = float3(1, 1, 1);
    return float4(color * totalDensity, totalDensity);
}
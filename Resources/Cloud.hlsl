// Copyright Epic Games, Inc. All Rights Reserved.


#include "./Resources/SkyAtmosphereCommon.hlsl"

// Cloud shader code is a shame but it does what it needs to in the end.

Texture2D<float4> ShadowmapTexture : register(t0);
Texture2D<float4> TransmittanceLutTexture : register(t1);

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

float4 CloudPixelShader(CloudVertexOutput input) :SV_TARGET
{
    float3 ray_direct = normalize(input.worldPos - camera);
    float step_size = 0.05;
    float3 rayOrigin = camera;
    float density = 0.000001;
    for (int i = 0; i < 1000; i++)
    {
        rayOrigin += (ray_direct * step_size);
        float spheredist = distance(rayOrigin, shpere_center);
        
        if (spheredist < 0.8)
        {
            density += 0.02;
        }
    }
    if (density > 1.0f)
        density = 1.0f;
    density *= 0.8;
    float alpha = density;
    float3 color = float3(1, 1, 1) * alpha;
    return float4(color, alpha);
}

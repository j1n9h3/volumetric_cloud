// Copyright Epic Games, Inc. All Rights Reserved.

#include "SkyAtmosphereCommon.hlsl"

cbuffer CommonBuffer : register(b0)
{
    float4x4 gViewProjMat;
    float4 gColor;
    float3 gSunIlluminance;
    int gScatteringMaxPathDepth;
    unsigned int gResolution[2];
    float gFrameTimeSec;
    float gTimeSec;
    unsigned int gMouseLastDownPos[2];
    unsigned int gFrameId;
    unsigned int gTerrainResolution;
    float gScreenshotCaptureActive;
    float RayMarchMinMaxSPP[2];
    float pad[2];
};

cbuffer SkyAtmosphereBuffer : register(b1)
{
    AtmosphereParameters Atmosphere;
    int TRANSMITTANCE_TEXTURE_WIDTH;
    int TRANSMITTANCE_TEXTURE_HEIGHT;
    int IRRADIANCE_TEXTURE_WIDTH;
    int IRRADIANCE_TEXTURE_HEIGHT;
    int SCATTERING_TEXTURE_R_SIZE;
    int SCATTERING_TEXTURE_MU_SIZE;
    int SCATTERING_TEXTURE_MU_S_SIZE;
    int SCATTERING_TEXTURE_NU_SIZE;
    float3 SKY_SPECTRAL_RADIANCE_TO_LUMINANCE;
    float pad3;
    float3 SUN_SPECTRAL_RADIANCE_TO_LUMINANCE;
    float pad4;
    float4x4 gSkyViewProjMat;
    float4x4 gSkyInvViewProjMat;
    float4x4 gSkyInvProjMat;
    float4x4 gSkyInvViewMat;
    float4x4 gShadowmapViewProjMat;
    float3 camera;
    float pad5;
    float3 sun_direction;
    float pad6;
    float3 view_ray;
    float pad7;
    float MultipleScatteringFactor;
    float MultiScatteringLUTRes;
    float pad9;
    float pad10;
};

Texture2D<float4> TransmittanceLutTexture : register(t0);
SamplerState samplerLinearClamp : register(s0);

struct CubeVertexOutput
{
    float4 position     : SV_POSITION;
    float3 worldPos    : TEXCOORD0;
    float3 normal      : TEXCOORD1;
};

CubeVertexOutput CubeVertexShader(uint vertexId : SV_VertexID)
{
    CubeVertexOutput output = (CubeVertexOutput)0;

    // Define cube vertices (8 corners)
    float3 vertices[8];
    vertices[0] = float3(-0.5f, -0.5f, -0.5f);
    vertices[1] = float3( 0.5f, -0.5f, -0.5f);
    vertices[2] = float3( 0.5f,  0.5f, -0.5f);
    vertices[3] = float3(-0.5f,  0.5f, -0.5f);
    vertices[4] = float3(-0.5f, -0.5f,  0.5f);
    vertices[5] = float3( 0.5f, -0.5f,  0.5f);
    vertices[6] = float3( 0.5f,  0.5f,  0.5f);
    vertices[7] = float3(-0.5f,  0.5f,  0.5f);

    // Define cube indices for triangles (12 triangles = 36 vertices)
    static const int indices[36] = {
        // Front face
        0, 1, 2, 0, 2, 3,
        // Back face
        4, 6, 5, 4, 7, 6,
        // Top face
        3, 2, 6, 3, 6, 7,
        // Bottom face
        0, 5, 4, 0, 1, 5,
        // Right face
        1, 5, 6, 1, 6, 2,
        // Left face
        0, 4, 7, 0, 7, 3
    };

    int faceIndex = vertexId / 6;
    int vertexInTriangle = vertexId % 3;

    int triangleIndex = (vertexId % 6) / 3;
    int index = faceIndex * 6 + triangleIndex * 3 + vertexInTriangle;

    float3 cubePos = vertices[indices[index]];

    // Position cube 100 meters above the terrain center
    const float terrainWidth = 100.0f; // 100 km edge
    const float cubeSize = 100.0f; // 100 meter cube
    const float cubeHeight = 100.0f; // 100 meters above terrain

    float3 worldPosition = cubePos * cubeSize;
    worldPosition.y += cubeHeight;
    worldPosition.x += terrainWidth * 0.45;
    worldPosition.z += 0.4 * terrainWidth;

    output.worldPos = float4(worldPosition, 1.0f);
    output.position = mul(gViewProjMat, output.worldPos);

    // Calculate normal based on face
    float3 normal;
    if (faceIndex == 0) normal = float3(0, 0, -1); // front
    else if (faceIndex == 1) normal = float3(0, 0, 1);  // back
    else if (faceIndex == 2) normal = float3(0, 1, 0);  // top
    else if (faceIndex == 3) normal = float3(0, -1, 0); // bottom
    else if (faceIndex == 4) normal = float3(1, 0, 0);  // right
    else normal = float3(-1, 0, 0); // left

    output.normal = normal;

    return output;
}

float4 CubePixelShader(CubeVertexOutput input) : SV_TARGET
{
    // Simple blue cube with basic lighting
    float3 cubeColor = float3(0.2f, 0.6f, 0.9f);
    float3 normal = normalize(input.normal);
    float NoL = max(0.0, dot(sun_direction, normal));

    float3 finalColor = cubeColor * NoL * 2.0f;

    return float4(finalColor, 1.0f);
}
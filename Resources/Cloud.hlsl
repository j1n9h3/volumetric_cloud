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


CloudVertexOutput CloudVertexShader(
    uint vertexId : SV_VertexID,
    uint instanceId : SV_InstanceID)
{
    CloudVertexOutput output;

    // Use same offset as terrain to ensure cloud is in view
    float4 worldPos = float4(cubeVertices[vertexId] + float3(0, 0, 1), 1.0f);
    output.worldPos = worldPos.xyz;
    output.position = mul(gViewProjMat, worldPos);

    return output;
}


float3 shpere_center = float3(0, 0, 0);
float radius = 0.5;

static const float light_sample_steps = 200;
static const int cloud_sample_steps = 200;
static const float step_size = 0.05;

static const float absorption_coeff =0.8;

float4 CloudPixelShader(CloudVertexOutput input) : SV_TARGET
{
    float3 ray_direct = normalize(input.worldPos - camera);
    float3 ray_point = camera;

    float transmittance = 1.0;
    float light_energy = 0;
        
    for (int i = 0; i < cloud_sample_steps; i++)
    {
        ray_point += (ray_direct * step_size);
        
        float3 uvw = (ray_point - float3(0, 0, 1)) * 0.5 + 0.5;
        
        if (all(uvw >= 0.0) && all(uvw <= 1.0))
        {
            float current_density = CloudTexture.SampleLevel(g_LinearSampler, uvw, 0).r;            
            if (current_density > 0.01)
            {
                float cloud_density_through_light = 0;
                float3 light_ray_point = ray_point;
                
                for (int j = 0; j < 200; j++)
                {
                    light_ray_point += sun_direction * step_size;
                    float3 l_uvw = (light_ray_point - float3(0, 0, 1)) * 0.5 + 0.5;
                    
                    if (all(l_uvw >= 0.0) && all(l_uvw <= 1.0))
                    {
                        cloud_density_through_light += CloudTexture.SampleLevel(g_LinearSampler, l_uvw, 0).r * step_size;
                    }
                }
                float light_transmission = exp(-cloud_density_through_light * absorption_coeff );
                
                light_energy += current_density * light_transmission * transmittance * step_size;
                transmittance *= exp(-current_density * absorption_coeff);
                if (transmittance < 0.01)
                    break;
            }
        }
    }

    float3 cloud_color = float3(1, 1, 1);
    float final_alpha = saturate(1.0 - transmittance);
    return float4(cloud_color * light_energy, final_alpha);
}
#include <metal_stdlib>
using namespace metal;
#import "Common.h"

struct VertexOut {
    float4 position [[position]];
    float point_size [[point_size]];
    float4 color;
};

kernel void computeParticles(
    device Particle *particles [[buffer(0)]],
    uint id [[thread_position_in_grid]])
{
    float xVelocity = particles[id].speed * cos(particles[id].direction);
    float yVelocity = particles[id].speed * sin(particles[id].direction);
    
    particles[id].position.x += xVelocity;
    particles[id].position.y += yVelocity;
    
    particles[id].age += 1.0;
    float age = particles[id].age / particles[id].life;
    particles[id].scale = mix(
        particles[id].startScale,
        particles[id].endScale,
        age);
    if (particles[id].age > particles[id].life) {
        particles[id].position = particles[id].startPosition;
        particles[id].age = 0;
        particles[id].scale = particles[id].startScale;
    }
}

vertex VertexOut vertex_particle(
    constant float2 &size [[buffer(0)]],
    const device Particle *particles [[buffer(1)]],
    constant float2 &emitterPosition [[buffer(2)]],
    uint instance [[instance_id]])
{
    float2 position = particles[instance].position + emitterPosition;
    VertexOut out {
        .position = float4(position.xy / size * 2.0 - 1.0, 0, 1),
        .point_size = particles[instance].size * particles[instance].scale,
        .color = particles[instance].color
    };
    return out;
}

fragment float4 fragment_particle(
    VertexOut in [[stage_in]],
    texture2d<float> particleTexture [[texture(0)]],
    float2 point [[point_coord]])
{
    constexpr sampler default_sampler;
    float4 color = particleTexture.sample(default_sampler, point);
    if (color.a < 0.5) {
        discard_fragment();
    }
    color = float4(color.xyz, 0.5);
    color *= in.color;
    return  color;
}

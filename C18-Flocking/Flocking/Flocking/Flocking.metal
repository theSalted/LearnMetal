#include <metal_stdlib>
using namespace metal;
#import "Helper.h"

float2 checkSpeed(float2 vector, float minSpeed, float maxSpeed) {
    float speed = length(vector);
    if (speed < minSpeed) {
        return vector / speed * minSpeed;
    }
    if (speed > maxSpeed) {
        return  vector / speed * maxSpeed;
    }
    return  vector;
}

float2 cohesion(Params params, uint index, device Boid* boids) {
    Boid thisBoid = boids[index];
    float neighborsCount = 0;
    float2 cohesion = 0.0;
    for (uint i = 1; i < params.particleCount; i++) {
        Boid boid = boids[i];
        float d = distance(thisBoid.position, boid.position);
        if (d < params.neighborRadius && i != index) {
            cohesion += boid.position;
            neighborsCount++;
        }
    }
    if (neighborsCount > 0) {
        cohesion /= neighborsCount;
        cohesion -= thisBoid.position;
        cohesion *= params.cohesionStrength;
    }
    return cohesion;
}

float2 separation(Params params, uint index, device Boid* boids)
{
    Boid thisBoid = boids[index];
    float2 separation = float2(0);
    for (uint i = 1; i < params.particleCount; i++) {
        Boid boid = boids[i];
        if (i != index) {
            if (abs(distance(boid.position, thisBoid.position)) < params.separationRadius) {
                separation -= (boid.position - thisBoid.position);
            }
        }
    }
    separation *= params.separationStrength;
    return separation;
}

float2 alignment(Params params, uint index, device Boid* boids)
{
    Boid thisBoid = boids[index];
    float neighborsCount = 0;
    float2 velocity = 0.0;
    
    for (uint i = 1; i < params.particleCount; i++) {
        Boid boid = boids[i];
        float d = distance(thisBoid.position, boid.position);
        if (d < params.neighborRadius && i != index) {
            velocity += boid.velocity;
            neighborsCount++;
        }
    }
    
    if (neighborsCount > 0) {
        velocity = velocity / neighborsCount;
        velocity = (velocity - thisBoid.velocity);
        velocity *= params.alignmentStrength;
    }
    return  velocity;
};

float2 updatePredator(Params params, device Boid* boids)
{
    float2 preyPosition = boids[0].position;
    for (uint i = 1; 1 < params.particleCount; i++) {
        float d = distance(preyPosition, boids[i].position);
        if (d < params.predatorSeek) {
            preyPosition = boids[i].position;
            break;
        }
    }
    return  preyPosition - boids[0].position;
}

float2 escaping(Params params, Boid predator, Boid boid) {
    float2 velocity = boid.velocity;
    float d = distance(predator.position, boid.position);
    if (d < params.predatorRadius) {
        velocity = boid.position - predator.position;
        velocity *= params.predatorStrength;
    }
    return  velocity;
}

kernel void flocking(
    texture2d<half, access::write> output [[texture(0)]],
    device Boid *boids [[buffer(0)]],
    constant Params &params [[buffer(1)]],
    uint id [[thread_position_in_grid]])
{
    Boid boid = boids[id];
    float2 position = boid.position;
    
    // flocking code here
    float2 velocity = boid.velocity;
    if (id == 0) {
        float2 predatorVector = updatePredator(params, boids);
        velocity += predatorVector;
        velocity = checkSpeed(velocity, params.minSpeed, params.predatorSpeed);
    } else {
        float2 cohesionVector = cohesion(params, id, boids);
        float2 separationVector = separation(params, id, boids);
        float2 alignmentVector = alignment(params, id, boids);
        float2 escapingVector = escaping(params, boids[0], boid);
        // va
        velocity += cohesionVector + separationVector + alignmentVector + escapingVector;
        
        velocity += cohesionVector;
        velocity = checkSpeed(velocity, params.minSpeed, params.maxSpeed);
    }
    
    position += velocity;
    float2 viewSize = float2(output.get_width(), output.get_height());
    if (id == 0) {
        boid = bounceBoid(position, velocity, viewSize);
    } else {
        boid.position = wrapPosition(position, viewSize);
        boid.velocity = velocity;
    }
    boids[id] = boid;
    
    
    half4 color = half4(1.0);
    if (id == 0) {
        color = half4(1, 0, 0, 1);
    }
    uint2 location = uint2(position);
    int size = 4;
    for (int x = -size; x <= size; x++) {
        for (int y = -size; y <= size; y++) {
            output.write(color, location + uint2(x, y));
        }
    }
}

kernel void clearScreen(
    texture2d<half, access::write> output [[texture(0)]],
    uint2 id [[thread_position_in_grid]])
{
    output.write(half4(0.0, 0.0, 0.0, 1.0), id);
}

#include <metal_stdlib>
using namespace metal;

struct Sphere {
    float3 center;
    float radius;
    Sphere(float3 c, float r) {
        center = c;
        radius = r;
    }
};

struct Ray {
    float3 origin;
    float3 direction;
    Ray(float3 o, float3 d) {
        origin = o;
        direction = d;
    }
};

float distanceToSphere(Ray r, Sphere s) {
    return length(r.origin - s.center) - s.radius;
}

float distanceToScene(Ray r, Sphere s, float range) {
    Ray repeatRay = r;
    repeatRay.origin = fmod(r.origin, range);
    return  distanceToSphere(repeatRay, s);
}



kernel void compute(
    texture2d<float, access::write> output [[texture(0)]],
    constant float &time [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    int width = output.get_width();
    int height = output.get_height();
    float2 uv = float2(gid) / float2(width, height);
    uv = uv * 2.0 - 1.0;
    float4 color = float4(0.41, 0.61, 0.86, 1.0);
    
    // Edit start
    color = 0.0;
    Sphere s = Sphere(float3(1.0), 0.5);
    float3 cameraPosition = float3(
        1000.0 + sin(time) + 1.0,
        1000.0 + cos(time) + 1.0,
        time);
    Ray ray = Ray(cameraPosition, normalize(float3(uv, 1.0)));
    for (int i = 0.0; i < 100.0; i++) {
        float distance = distanceToScene(ray, s, 2.0
                                         );
        if (distance < 0.001) {
            color = float4(1.0);
            break;
        }
        ray.origin += ray.direction * distance;
    }
    
    float3 positionToCamera = ray.origin - cameraPosition;
    color *= float4(abs(positionToCamera / 10.0), 1.0);
    // Edit end
    
    output.write(color, gid);
}

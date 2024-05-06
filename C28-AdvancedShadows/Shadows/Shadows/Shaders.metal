#include <metal_stdlib>
using namespace metal;

struct Rectangle {
    float2 center;
    float2 size;
};

struct Ray {
    float3 origin;
    float3 direction;
};

struct Sphere {
    float3 center;
    float radius;
};

struct Plane {
    float yCoord;
};

struct Light {
    float3 position;
};

float disToSphere(Ray ray, Sphere s) {
    return length(ray.origin - s.center) - s.radius;
}

float distToPlane(Ray ray, Plane plane) {
    return  ray.origin.y - plane.yCoord;
}

float differenceOp(float d0, float d1) {
    return  max(d0, -d1);
}

float unionOp(float d0, float d1) {
    return  min(d0, d1);
}

float distToScene(Ray r) {
    Plane p = Plane{0.0};
    float d2p = distToPlane(r, p);
    Sphere s1 = Sphere { float3(2.0), 2.0 };
    Sphere s2 = Sphere { float3(0.0, 4.0, 0.0), 4.0 };
    Sphere s3 = Sphere { float3(0.0, 4.0, 0.0), 3.9 };
    
    Ray repeatRay = r;
    repeatRay.origin = fract(r.origin / 4.0) * 4.0;
    
    float d2s1 = disToSphere(repeatRay, s1);
    float d2s2 = disToSphere(r, s2);
    float d2s3 = disToSphere(r, s3);
    
    float dist = differenceOp(d2s2, d2s3);
    dist = differenceOp(dist, d2s1);
    dist = unionOp(d2p, dist);
    return dist;
}

float3 getNormal(Ray ray) {
    float2 eps = float2(0.001, 0.0);
    float3 n = float3(
        distToScene(Ray{ray.origin + eps.xyy, ray.direction}) -
        distToScene(Ray{ray.origin - eps.xyy, ray.direction}),
        distToScene(Ray{ray.origin + eps.yxy, ray.direction}) -
        distToScene(Ray{ray.origin - eps.yxy, ray.direction}),
        distToScene(Ray{ray.origin + eps.yyx, ray.direction}) -
        distToScene(Ray{ray.origin - eps.yyx, ray.direction}));
    return normalize(n);
}

float distanceToRectangle(float2 point, Rectangle rectangle) {
    float2 distances = abs(point - rectangle.center) - rectangle.size / 2;
    return all(sign(distances) > 0) ? length(distances) : max(distances.x, distances.y);
}

float differenceOperator(float d0, float d1) {
    return max(d0, -d1);
}
float distanceToScene(float2 point) {
    Rectangle r1 = Rectangle {
        float(0.0),
        float(0.3)
    };
    float d2r1 = distanceToRectangle(point, r1);
    
    Rectangle r2 = Rectangle {
        float(0.05),
        float(0.04)
    };
    float2 mod = point - 0.1 * floor(point / 0.1);

    float d2r2 = distanceToRectangle(mod, r2);
    
    float diff = differenceOperator(d2r1, d2r2);
    
    return diff;
}

float getShadow(float2 point, float2 lightPos)
{
    float2 lightDir = normalize(lightPos - point);
    float shadowDistance = 0.75;
    float distAlongRay = 0.0;
    for (float i = 0; i < 80; i++) {
        float2 currentPoint = point + lightDir * distAlongRay;
        float d2scene = distanceToScene(currentPoint);
        if (d2scene <= 0.001) { return  0.0; }
        distAlongRay += d2scene;
        if (distAlongRay > shadowDistance) { break; }
    }
    return 1.0;
}

float lighting(Ray ray, float3 normal, Light light) {
    float3 lightRay = normalize(light.position - ray.origin);
    float diffuse = max(0.0, dot(normal, lightRay));
    float3 reflectedRay = reflect(ray.direction, normal);
    float specular = max(0.0, dot(reflectedRay, lightRay));
    specular = pow(specular, 200.0);
    return  diffuse + specular;
}

float shadow(Ray ray, Light light) {
    float3 lightDir = light.position - ray.origin;
    float lightDis = length(lightDir);
    lightDir = normalize(lightDir);
    float distAlongRay = 0.01;
    for (int i = 0; i < 100; i++) {
        Ray lightRay = Ray {ray.origin + lightDir * distAlongRay, lightDir};
        float dist = distToScene(lightRay);
        if (dist < 0.001) { return  0.0; }
        distAlongRay += dist;
        if (distAlongRay > lightDis ) { break; }
    }
    return 1.0;
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
    float4 color = float4(0.9, 0.9, 0.8, 1.0);
    
    // Edit start
    
    color = 0;
    uv.y = -uv.y;
    Ray ray = Ray { float3(0., 4., -12), normalize(float3(uv, 1.))};
    
    for (int i = 0; i < 100; i++) {
        float dist = distToScene(ray);
        
        if (dist < 0.001) {
            color = 1.0;
            break;;
        }
        ray.origin += ray.direction * dist;
    }
    
    float3 n = getNormal(ray);
    
    Light light = Light{ float3(sin(time) * 10.0, 5.0, cos(time) * 10.0)};
    float l = lighting(ray, n, light);
    
    float s = shadow(ray, light);
    
    color = float4(color.xyz * l * s, 1.0);
    
    

    // Edit end
    output.write(color, gid);
}

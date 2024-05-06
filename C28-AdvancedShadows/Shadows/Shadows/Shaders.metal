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

struct Box {
    float3 center;
    float size;
};

struct Camera {
    float3 position;
    Ray ray{float3(0), float3(0)};
    float rayDivergence;
};

float distToSphere(Ray ray, Sphere s) {
    return length(ray.origin - s.center) - s.radius;
}

float distToPlane(Ray ray, Plane plane) {
    return  ray.origin.y - plane.yCoord;
}

float distToBox(Ray r, Box b) {
    float3 d = abs(r.origin - b.center) - float3(b.size);
    return  min(max(d.x, max(d.y, d.z)), 0.0 + length(max(d, 0.0)));
}

float differenceOp(float d0, float d1) {
    return  max(d0, -d1);
}

float unionOp(float d0, float d1) {
    return  min(d0, d1);
}


float distToScene(Ray r) {
    Plane p{0.0};
    float d2p = distToPlane(r, p);
    
    Sphere s1 = Sphere{float3(0.0, 0.5, 0.0), 8.0};
    Sphere s2 = Sphere{float3(0.0, 0.5, 0.0), 6.0};
    Sphere s3 = Sphere{float3(10.0, -5., -10.), 15.0};
    
    float d2s1 = distToSphere(r, s1);
    float d2s2 = distToSphere(r, s2);
    float d2s3 = distToSphere(r, s3);
    
    float dist = differenceOp(d2s1, d2s2);
    dist = differenceOp(dist, d2s3);
    
    Box b = Box{float3(1., 1., -4.), 1.};
    float dtb = distToBox(r, b);
    dist = unionOp(dist, dtb);
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

float shadow(Ray ray, float k, Light l) {
    float3 lightDir = l.position - ray.origin;
    float lightDis = length(lightDir);
    lightDir = normalize(lightDir);
    
    float light = 1.0;
    float eps = 0.1;
    
    float distAlongRay = eps * 2.0;
    
    for (int i = 0; i < 100; i++) {
        Ray lightRay = Ray {ray.origin + lightDir * distAlongRay, lightDir};
        
        float dist = distToScene(lightRay);
        
        light = min(light, 1.0 - (eps - dist) / eps);
        
        distAlongRay += dist * 0.5;
        eps += dist * k;
        
        if (distAlongRay > lightDis ) { break; }
    }
    return max(light, 0.0);
}

float ao(float3 pos, float3 n) {
    float eps = 0.01;
    pos += n * eps * 2.0;
    float occlusion = 0.0;
    
    for (float i = 1.0; i < 10.0; i++) {
        float d = distToScene(Ray{pos, float3(0)});
        float coneWidth = 2.0 * eps;
        float occlusionAmount = max(coneWidth - d, 0.);
        float occlusionFactor = occlusionAmount / coneWidth;
        
        occlusionFactor *= 1.0 - (i / 10.0);
        occlusion = max(occlusion, occlusionFactor);
        
        eps *= 2.0;
        pos += n * eps;
    }
    
    return  max(0.0, 1.0 - occlusion);
}

Camera setupCam(float3 pos, float3 target,
                float fov, float2 uv, int x)
{
    uv *= fov;
    float3 cw = normalize(target - pos);
    float3 cp = float3(0.0, 1.0, 0.0);
    float3 cu = normalize(cross(cw, cp));
    float3 cv = normalize(cross(cu, cw));
    
    Ray ray = Ray{pos,
        normalize(uv.x * cu + uv.y * cv + 0.5 * cw)
    };
    Camera cam = Camera{pos, ray, fov / float(x)};
    return cam;
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
    
    
    float3 camPos = float3(sin(time) * 10., 3., cos(time) * 10.);
    Camera cam = setupCam(camPos, float3(0), 1.2, uv, width);
    Ray ray = cam.ray;
    
    
    bool hit = false;
    for (int i = 0; i < 200; i++) {
        float dist = distToScene(ray);
        if (dist < 0.001) {
            hit = true;
            break;
        }
        ray.origin += ray.direction * dist;
    }
    // 2
    float3 col = 1.0;
    // 3
    if (!hit) {
        col = float3(0.8, 0.5, 0.5);
    } else {
        float3 n = getNormal(ray);
        
        float o = ao(ray.origin, n);
        col = col * o;
    }
    // 4
    Light light2 = Light{float3(0.0, 5.0, -15.0)};
    
    color = float4(col, 1.0);
    
    // Edit end
    output.write(color, gid);
}

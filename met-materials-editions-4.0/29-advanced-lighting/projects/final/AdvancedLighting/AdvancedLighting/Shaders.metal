///// Copyright (c) 2023 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

#include <metal_stdlib>
using namespace metal;

constant float PlaneObj = 0.0;
constant float SphereObj = 1.0;

struct Ray {
  float3 origin;
  float3 dir;
};

struct Light {
  float3 pos;
};

struct Camera {
  float3 pos;
  Ray ray;
  float rayDivergence;
};

struct Sphere {
  float3 center;
  float radius;
};

struct Plane {
  float yCoord;
};

float unionOp(float d0, float d1) {
  return min(d0, d1);
}

float distToSphere(Ray r, Sphere s) {
  float d = distance(r.origin, s.center);
  return d - s.radius;
}

float distToPlane(Ray r, Plane p) {
  return r.origin.y - p.yCoord;
}

float2 distToScene(Ray r) {
  Plane p = Plane{0.0};
  float dtp = distToPlane(r, p);
  Sphere s = Sphere{float3(0.0, 6.0, 0.0), 6.0};
  float dts = distToSphere(r, s);
  float object = (dtp > dts) ? SphereObj : PlaneObj;
  if (object == SphereObj) {
    float3 pos = r.origin;
    pos += float3(sin(pos.y * 5.0),
                  sin(pos.z * 5.0),
                  sin(pos.x * 5.0)) * 0.05;
    Ray ray = Ray{pos, r.dir};
    dts = distToSphere(ray, s);
  }
  float dist = unionOp(dts, dtp);
  return float2(dist, object);
}

float3 getNormal(Ray ray) {
  float2 eps = float2(0.001, 0.0);
  float3 n = float3(distToScene(Ray{ray.origin + eps.xyy, ray.dir}).x -
                    distToScene(Ray{ray.origin - eps.xyy, ray.dir}).x,
                    distToScene(Ray{ray.origin + eps.yxy, ray.dir}).x -
                    distToScene(Ray{ray.origin - eps.yxy, ray.dir}).x,
                    distToScene(Ray{ray.origin + eps.yyx, ray.dir}).x -
                    distToScene(Ray{ray.origin - eps.yyx, ray.dir}).x);
  return normalize(n);
}

Camera setupCam(float3 pos, float3 target, float fov, float2 uv, float width) {
  uv *= fov;
  float3 cw = normalize (target - pos);
  float3 cp = float3 (0.0, 1.0, 0.0);
  float3 cu = normalize(cross(cw, cp));
  float3 cv = normalize(cross(cu, cw));
  float3 dir = normalize (uv.x * cu + uv.y * cv + 0.5 * cw);
  Ray ray{pos, dir};
  Camera cam{pos, ray, fov / width};
  return cam;
}

float mod(float x, float y) {
  return x - y * floor(x / y);
}

Camera reflectRay(Camera cam, float3 n, float eps) {
  cam.ray.origin += n * eps;
  cam.ray.dir = reflect(cam.ray.dir, n);
  return cam;
}

Camera refractRay(Camera cam, float3 n, float eps, float ior) {
  cam.ray.origin -= n * eps * 2.0;
  cam.ray.dir = refract(cam.ray.dir, n, ior);
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
  uv.y *= -1.0;
  float3 camPos = float3(sin(time) * 15.0,
                         sin(time) * 5.0 + 7.0,
                         cos(time) * 15.0);
  Camera cam = setupCam(camPos, float3(0.0), 1.25, uv, float(width));
  float3 col = float3(0.9);
  float eps = 0.01;
  bool inside = false;
  for (int i = 0; i < 300; i++) {
    float2 dist = distToScene(cam.ray);
    dist.x *= inside ? -1.0 : 1.0;
    float closestObject = dist.y;
    if (dist.x < eps) {
      float3 normal = getNormal(cam.ray) * (inside ? -1.0 : 1.0);
      if (closestObject == PlaneObj) {
        float2 pos = cam.ray.origin.xz;
        pos *= 0.1;
        pos = floor(fmod(pos, 2.0));
        float check = mod(pos.x + pos.y, 2.0);
        col *= check * 0.5 + 0.5;
        cam = reflectRay(cam, normal, eps);
      } else if (closestObject == SphereObj) {
        inside = !inside;
        float ior = inside ? 1.0 / 1.33 : 1.33;
        cam = refractRay(cam, normal, eps, ior);
      }
    }
    cam.ray.origin += cam.ray.dir * dist.x * 0.5;
    eps += cam.rayDivergence * dist.x;
  }
  col *= mix(float3(0.8, 0.8, 0.4), float3(0.4, 0.4, 1.0),
             cam.ray.dir.y);
  output.write(float4(col, 1.0), gid);
}

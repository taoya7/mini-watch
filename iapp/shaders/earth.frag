#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash(i),                  hash(i + vec2(1.0, 0.0)), u.x),
    mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
    u.y
  );
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p *= 2.0;
    a *= 0.5;
  }
  return v;
}

float fluid(vec2 p, float t) {
  vec2 q = vec2(fbm(p + vec2(0.0, t * 0.10)),
                fbm(p + vec2(5.2, 1.3)));
  vec2 r = vec2(fbm(p + 4.0 * q + vec2(1.7, 9.2) + t * 0.12),
                fbm(p + 4.0 * q + vec2(8.3, 2.8) + t * 0.10));
  return fbm(p + 4.0 * r);
}

void main() {
  vec2 uv = (FlutterFragCoord().xy / uSize - 0.5) * 2.0;
  float aspect = uSize.x / uSize.y;
  uv.x *= aspect;

  float d = length(uv);

  if (d > 1.0) {
    float glow = smoothstep(1.12, 1.0, d);
    float a = glow * 0.22;
    fragColor = vec4(vec3(0.30, 0.55, 0.95) * a, a);
    return;
  }

  vec3 p = vec3(uv, sqrt(1.0 - d * d));

  float t = uTime * 0.25;
  float c = cos(t), s = sin(t);
  vec3 sp = vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);

  float lat = asin(sp.y) / 3.14159 + 0.5;
  float lon = atan(sp.z, sp.x) / (2.0 * 3.14159) + 0.5;

  vec2 sUV = vec2(lon * 3.0, lat * 2.5);
  float f = fluid(sUV, uTime * 0.6);

  vec3 cDeep   = vec3(0.04, 0.13, 0.40);
  vec3 cMid    = vec3(0.18, 0.55, 0.85);
  vec3 cBright = vec3(0.85, 0.96, 1.00);

  vec3 color = mix(cDeep, cMid, smoothstep(0.25, 0.55, f));
  color = mix(color, cBright, smoothstep(0.70, 0.92, f));

  vec3 lightDir = normalize(vec3(-0.45, 0.55, 0.85));
  float diff = max(dot(p, lightDir), 0.0);
  color *= 0.18 + 0.82 * diff;

  float rim = pow(1.0 - p.z, 2.5);
  color += rim * vec3(0.40, 0.60, 0.90) * 0.55;

  float alpha = smoothstep(1.0, 0.985, d);
  fragColor = vec4(color, alpha);
}

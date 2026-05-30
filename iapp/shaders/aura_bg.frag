#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uColor;
uniform sampler2D uPerlin;
uniform sampler2D uPerlin2;
uniform sampler2D uBlueNoise;
out vec4 fragColor;

const float PI = 3.14159265358979323846;

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

vec2 barrel(vec2 uv, float amount) {
  vec2 dir = uv - 0.5;
  float dist = length(dir);
  float power = smoothstep(0.0, 1.0, 1.0 - dist);
  return uv + dir * power * amount;
}

mat2 rotate(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

vec2 twirlUv(vec2 uv, float influence) {
  float angle = influence * 0.5;
  vec2 offset = uv - 0.5;
  return rotate(angle) * offset + 0.5;
}

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float _time = uTime;
  vec2 screenUv = frag / uSize;
  vec2 vUv = vec2(screenUv.x, 1.0 - screenUv.y);
  vec2 pxUv = frag;

  float dist = distance(vUv, vec2(0.5));
  vec3 tint = max(uColor, vec3(0.001));

  vec2 uvm = vec2(0.3, 0.9) * 0.9;
  vec2 uvo = vec2(1.8, 0.0);
  vec2 uvb = mod(vUv + vec2(0.5, 0.0) + uvo, 1.0) * uvm;
  vec3 nb = texture(uPerlin2, fract(uvb + vec2(-2.2, 2.4))).rgb;
  float bmask = smoothstep(0.0, 0.3 + nb.g * 0.02, abs(mod(vUv.x + uvo.x, 1.0) - 0.5));
  vec3 scene = vec3(0.0003, 0.0030, 0.1221);
  scene.b += nb.b * bmask * smoothstep(0.4, 1.0, nb.g) * 0.4;
  scene = mix(scene, vec3(0.0), smoothstep(0.4, 1.0, vUv.y));
  scene = mix(scene, vec3(0.0003, 0.0030, 0.1221), smoothstep(0.5, 0.0, vUv.y));
  scene *= 1.4;

  vec2 ditherOffset = floor(vec2(
    hash(vec2(floor(_time * 83.0), 17.0)),
    hash(vec2(29.0, floor(_time * 71.0)))
  ) * 128.0) / 128.0;
  vec3 dither = texture(uBlueNoise, fract(pxUv * 0.015625 + ditherOffset)).rgb;

  vec3 perlin = texture(
    uPerlin,
    fract(pxUv * 0.0003 + _time * 0.03 + cos(_time + pxUv.y * 0.006) * 0.05)
  ).rgb * 2.0 - 1.0;

  vec2 warpedUv = barrel(vUv, 0.02);
  float pv =
    smoothstep(0.5, 0.45, abs(warpedUv.x - 0.5)) *
    smoothstep(0.5, 0.45, abs(warpedUv.y - 0.5));
  warpedUv += (perlin.bg * 3.0 + cos(_time * 0.5 + pxUv.x * 0.0002) * 0.7) * pv * 0.009;
  warpedUv.x += sin(vUv.y * 1000.0) * 0.003 * pv;
  float rnd = dither.x - 0.5;
  float ang = dither.y * PI * 2.0;
  warpedUv += vec2(cos(ang), sin(ang)) * rnd * 0.024;

  const float gridSpace = 23.5;
  vec2 gridUv = (barrel(vUv, 0.1) - 0.5) * uSize;
  gridUv.x += _time * 120.0;
  gridUv.x += cos(gridUv.y * 0.013 + perlin.g * 0.21) * 66.0 + perlin.b * 30.0;
  gridUv.y += cos(pxUv.x * 0.006 + _time * 0.2 + perlin.b * 1.2 + gridUv.x * 0.004) * 32.0;
  gridUv = abs(mod(gridUv, vec2(gridSpace)) - gridSpace * 0.5);
  float grid =
    smoothstep(1.6, -0.5, gridUv.y) *
    (1.3 - smoothstep(-0.5, 0.5, perlin.b) * 0.7) *
    smoothstep(0.7, 0.1, dist) *
    0.45 *
    smoothstep(0.6, 0.8, cos(pxUv.x * 0.6));

  vec2 cell = floor(((barrel(vUv, 0.1) - 0.5) * uSize + _time * vec2(120.0, 0.0)) / gridSpace);
  grid *= 0.78 + 0.22 * hash(cell);

  vec3 diffuse = scene;
  vec3 insideColor = vec3(luma(diffuse) * 0.3 + 0.098) * tint;
  insideColor = mix(insideColor, tint + 0.3, grid);

  vec2 viv = (vUv - 0.5) + perlin.gr * 0.03;
  float insideVignetteInfl = distance(viv, vec2(0.0));
  insideColor = mix(
    insideColor,
    mix(insideColor * 1.5 + 0.3, tint, 0.2),
    smoothstep(0.4, 0.9, insideVignetteInfl)
  );
  insideColor = mix(
    insideColor,
    tint * 1.2 + 0.1,
    smoothstep(0.57, 0.9, insideVignetteInfl) * 0.7
  );
  diffuse = insideColor;

  vec3 fineNoise = dither - 0.5;
  diffuse += fineNoise * 0.018;
  diffuse += tint * grid * 0.16;

  float vignette = pow(dist, 5.0);
  diffuse = mix(diffuse, diffuse - 1.7, vignette);

  float breath = 0.72 + 0.28 * sin(_time * 0.7);
  vec2 q = screenUv;
  float edge =
    smoothstep(0.30, 0.0, q.x) +
    smoothstep(0.30, 0.0, 1.0 - q.x) +
    smoothstep(0.34, 0.0, q.y) +
    smoothstep(0.34, 0.0, 1.0 - q.y);
  vec2 aspectUv = (q - 0.5) * vec2(uSize.x / max(uSize.y, 1.0), 1.0);
  float cornerGlow =
    smoothstep(0.72, 0.0, length(aspectUv - vec2(-0.42, -0.30))) +
    smoothstep(0.72, 0.0, length(aspectUv - vec2( 0.42, -0.28))) +
    smoothstep(0.72, 0.0, length(aspectUv - vec2(-0.44,  0.30))) +
    smoothstep(0.72, 0.0, length(aspectUv - vec2( 0.44,  0.28)));
  diffuse += tint * (edge * 0.030 + cornerGlow * 0.050) * breath;

  fragColor = vec4(clamp(diffuse * 1.1, 0.0, 1.0), 1.0);
}

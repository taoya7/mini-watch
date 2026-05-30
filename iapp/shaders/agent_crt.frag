#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uPixel;
uniform float uScanline;
uniform float uChroma;
uniform float uCurve;
out vec4 fragColor;

float roundedPanel(vec2 uv, vec2 c, vec2 halfSize, float r, float soft) {
  vec2 d = abs(uv - c) - halfSize + r;
  float dist = length(max(d, 0.0)) - r;
  return 1.0 - smoothstep(-soft, soft, dist);
}

float softDot(vec2 uv, vec2 c, float r) {
  return 1.0 - smoothstep(r * 0.4, r, length(uv - c));
}

vec3 sourceScene(vec2 uv) {
  float t = uTime;
  float aspect = uSize.x / max(uSize.y, 1.0);
  vec3 color1 = vec3(0.008, 0.067, 0.039);
  vec3 color2 = vec3(0.024, 0.216, 0.114);

  vec3 color = mix(color1, color2, pow(uv.y, 1.15));
  vec2 p = vec2(uv.x * aspect, uv.y);
  float flow =
    sin((p.x * 1.3 + p.y * 0.9 + t * 0.05) * 6.28318) +
    sin((p.x * 0.7 - p.y * 1.5 - t * 0.04) * 6.28318) * 0.6;
  flow = flow * 0.5 + 0.5;
  color += vec3(0.06, 0.065, 0.085) * (flow * 0.5 + 0.5);

  float card = roundedPanel(uv, vec2(0.5, 0.5), vec2(0.27, 0.21), 0.06, 0.04);
  color += vec3(0.22, 0.25, 0.32) * card;

  float bar = roundedPanel(uv, vec2(0.5, 0.60), vec2(0.17, 0.028), 0.02, 0.02);
  color += vec3(0.40, 0.43, 0.50) * bar;

  float btn = roundedPanel(uv, vec2(0.5, 0.42), vec2(0.085, 0.032), 0.03, 0.02);
  color += vec3(0.55, 0.58, 0.66) * btn;

  float dots = 0.0;
  dots += softDot(vec2(uv.x * aspect, uv.y), vec2(0.30 * aspect, 0.82), 0.05);
  dots += softDot(vec2(uv.x * aspect, uv.y), vec2(0.74 * aspect, 0.84), 0.05);
  dots += softDot(vec2(uv.x * aspect, uv.y), vec2(0.16 * aspect, 0.50), 0.05);
  dots += softDot(vec2(uv.x * aspect, uv.y), vec2(0.30 * aspect, 0.18), 0.05);
  dots += softDot(vec2(uv.x * aspect, uv.y), vec2(0.78 * aspect, 0.18), 0.05);
  color += vec3(0.26, 0.29, 0.36) * dots;

  float glow = pow(clamp(1.0 - length((uv - vec2(0.5, 0.46)) * vec2(aspect, 1.0)) * 0.9, 0.0, 1.0), 2.2);
  color += vec3(0.045, 0.05, 0.07) * glow;
  color *= 1.0 - 0.16 * length(uv - 0.5);

  return clamp(color, 0.0, 1.0);
}

vec3 sampleSource(vec2 uv) {
  uv = clamp(uv, vec2(0.001), vec2(0.999));
  return sourceScene(uv);
}

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  uv.y = 1.0 - uv.y;
  float time = uTime;

  vec2 centered = uv * 2.0 - 1.0;
  float r2 = dot(centered, centered);
  vec2 panelWarp = centered * (r2 * 0.02 * uCurve);
  vec2 screenUv = clamp(uv + panelWarp, vec2(0.001), vec2(0.999));

  vec2 lcdResolution = max(
    floor(uSize * vec2(0.48, 0.24) * uPixel * (1.0 + sin(time * 0.05) * 0.2)),
    vec2(120.0, 48.0)
  );
  vec2 lcdPixel = screenUv * lcdResolution;
  vec2 lcdCell = floor(lcdPixel);
  vec2 lcdFrac = fract(lcdPixel) - 0.5;
  vec2 snappedUv = (lcdCell + 0.5) / lcdResolution;
  vec2 lcdTexel = 1.0 / lcdResolution;

  vec3 centerSample = sampleSource(snappedUv);
  vec3 bleedX = sampleSource(snappedUv + vec2(lcdTexel.x * 0.65, 0.0));
  vec3 bleedY = sampleSource(snappedUv + vec2(0.0, lcdTexel.y * 0.55));
  vec3 color = centerSample * 0.82 + bleedX * 0.12 + bleedY * 0.06;

  vec2 chromaOffset = vec2(lcdTexel.x * 2.45 * uChroma, 0.0);
  vec3 chroma = vec3(
    sampleSource(snappedUv + chromaOffset).r,
    centerSample.g,
    sampleSource(snappedUv - chromaOffset).b
  );

  float scanline = mix(
    1.0,
    0.9 + 0.1 * cos((lcdFrac.y + time * 0.7) * 3.14159),
    uScanline
  );
  float verticalGate = smoothstep(0.72, 0.02, abs(lcdFrac.y));
  float pixelGate = smoothstep(0.64, 0.06, abs(lcdFrac.x)) * verticalGate;
  float sweep = 1.0 + 0.045 * sin((screenUv.y * 18.0 - time * 2.4) * 6.28318);

  float subpixel = fract(lcdPixel.x / 3.0);
  vec3 mask = vec3(
    smoothstep(0.0, 0.18, 0.32 - abs(subpixel - 0.166)),
    smoothstep(0.0, 0.18, 0.32 - abs(subpixel - 0.5)),
    smoothstep(0.0, 0.18, 0.32 - abs(subpixel - 0.833))
  );
  mask = mix(vec3(0.93), vec3(1.05, 1.01, 0.97), mask);

  color = mix(color, chroma, 0.56);
  color *= mask;
  color *= scanline * pixelGate * sweep;
  color = mix(color, color * vec3(0.96, 1.0, 0.94), 0.12);
  color *= 1.08;

  float vignette = smoothstep(0.45, 1.18, length(centered));
  color *= 1.0 - vignette * 0.28;
  color += (hash(lcdCell + floor(time * 60.0)) - 0.5) * 0.018;

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}

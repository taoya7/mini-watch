#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uColor;
uniform float uIntensity;
out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 uv = (FlutterFragCoord().xy / uSize - 0.5) * 2.0;
  uv.x *= uSize.x / uSize.y;

  float d = length(uv);
  if (d > 1.0) {

    fragColor = vec4(0.0);
    return;
  }

  float lit = clamp(uIntensity, 0.0, 1.0);
  float glow = smoothstep(0.0, 1.0, lit);

  float sphere = sqrt(max(0.0, 1.0 - d * d));
  float fresnel = pow(smoothstep(0.05, 1.0, d), 2.2);
  float centerGlow = pow(max(0.0, 1.0 - d), 1.8);

  vec3 glass = uColor.rgb * (0.035 + 0.045 * sphere);
  glass += vec3(0.018, 0.015, 0.012) * (1.0 - d);

  vec3 lamp = uColor.rgb * (0.18 + 1.25 * centerGlow + 0.45 * sphere);
  lamp *= mix(0.10, 1.0, glow);
  vec3 base = mix(glass, lamp, glow);
  base += uColor.rgb * fresnel * (0.05 + 0.22 * glow);

  vec2 hl = uv - vec2(-0.35, -0.40);
  float highlight = pow(smoothstep(0.42, 0.0, length(hl)), 1.6);
  base += vec3(highlight) * mix(0.10, 0.62, glow);
  vec2 streakUv = (uv - vec2(-0.10, -0.30)) * vec2(1.8, 5.0);
  float streak = smoothstep(0.42, 0.0, length(streakUv));
  base += vec3(streak) * 0.12 * (0.25 + glow);

  float grain = hash(FlutterFragCoord().xy + uTime * 60.0) - 0.5;
  base += grain * mix(0.025, 0.055, glow);

  base = mix(base, base * vec3(1.06, 0.96, 0.86), 0.35);

  float alpha = smoothstep(1.0, 0.96, d);
  fragColor = vec4(base, alpha);
}

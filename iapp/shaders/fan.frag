#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uColor;
out vec4 fragColor;

const float PI = 3.14159265359;
const float BLADES = 5.0;

void main() {
  vec2 uv = (FlutterFragCoord().xy / uSize - 0.5) * 2.0;
  uv.x *= uSize.x / uSize.y;

  float r = length(uv);
  if (r > 1.05) {
    fragColor = vec4(0.0);
    return;
  }

  float a = atan(uv.y, uv.x) + uTime * 3.0;
  float twist = (1.0 - r) * 0.9;
  float aBlade = a + twist;

  float seg = 2.0 * PI / BLADES;
  float aMod = mod(aBlade + seg * 0.5, seg) - seg * 0.5;

  float widthAtR = mix(0.55, 0.12, smoothstep(0.2, 1.0, r));

  float aa = 0.03;
  float bladeMask = 1.0 - smoothstep(widthAtR - aa, widthAtR + aa, abs(aMod));

  float radialMask =
      smoothstep(0.20, 0.24, r) * smoothstep(0.96, 0.88, r);
  bladeMask *= radialMask;

  float hubMask = smoothstep(0.24, 0.20, r);

  float hubLight = smoothstep(0.10, 0.04, r);

  vec3 col = uColor.rgb;
  col += bladeMask * pow(r, 1.5) * 0.5;

  vec3 hubCol = uColor.rgb * 0.55 + vec3(hubLight) * 0.6;

  float bladeA = bladeMask * uColor.a;
  float hubA = hubMask * uColor.a;

  vec3 finalCol = mix(col, hubCol, hubA);
  float finalA = max(bladeA, hubA);

  fragColor = vec4(finalCol * finalA, finalA);
}

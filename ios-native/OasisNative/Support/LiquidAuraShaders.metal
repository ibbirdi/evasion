#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

static inline float2 rotate2d(float2 point, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float2(
        (point.x * c) - (point.y * s),
        (point.x * s) + (point.y * c)
    );
}

static inline float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static inline float value_noise(float2 p) {
    float2 cell = floor(p);
    float2 local = fract(p);
    float2 smooth = local * local * (3.0 - (2.0 * local));

    float a = hash21(cell);
    float b = hash21(cell + float2(1.0, 0.0));
    float c = hash21(cell + float2(0.0, 1.0));
    float d = hash21(cell + float2(1.0, 1.0));

    return mix(
        mix(a, b, smooth.x),
        mix(c, d, smooth.x),
        smooth.y
    );
}

static inline float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;

    for (int octave = 0; octave < 3; octave++) {
        value += amplitude * value_noise(p);
        p = rotate2d((p * 2.02) + 13.7, 0.58);
        amplitude *= 0.5;
    }

    return value;
}

static inline float blob(float2 point, float2 center, float2 radius) {
    float2 delta = (point - center) / radius;
    float dist = dot(delta, delta);
    return exp(-dist * 3.0);
}

[[ stitchable ]] half4 liquidAuraFill(
    float2 position,
    float2 size,
    float time,
    float seedA,
    float seedB,
    half4 c0,
    half4 c1,
    half4 c2,
    half4 c3,
    half4 c4,
    half4 c5,
    half4 c6,
    half4 c7,
    float intensity,
    float softness,
    float speedMultiplier,
    float coverage,
    float accentMixAmount,
    float colorSeparation
) {
    float2 safeSize = max(size, float2(1.0, 1.0));
    float2 uv = position / safeSize;
    float aspect = safeSize.x / safeSize.y;
    float2 point = uv - 0.5;
    point.x *= aspect;

    float t = time * (0.44 + (speedMultiplier * 0.28));
    float fieldRotation = (t * 0.16) + (seedA * 6.2831853);
    float2 p = rotate2d(point, fieldRotation);

    float2 warp = float2(
        fbm((p * 1.24) + float2(t * 0.10, -t * 0.07) + (seedA * 5.0)),
        fbm(rotate2d(p, 1.08) * 1.18 + float2(-t * 0.08, t * 0.11) + (seedB * 7.0))
    ) - 0.5;
    p += warp * 0.12;

    float2 shapePoint = p;
    shapePoint.x /= max(1.0, coverage);

    float2 center0 = rotate2d(float2(-0.56, -0.10) + float2(cos(t * 0.34 + 1.2), sin(t * 0.28 + 0.3)) * float2(0.22, 0.14), t * 0.09);
    float2 center1 = rotate2d(float2(-0.18, 0.18) + float2(sin(t * 0.26 + 2.4), cos(t * 0.31 + 0.8)) * float2(0.18, 0.20), t * -0.07);
    float2 center2 = rotate2d(float2(0.18, -0.14) + float2(cos(t * 0.22 + 3.7), sin(t * 0.25 + 2.0)) * float2(0.20, 0.16), t * 0.11);
    float2 center3 = rotate2d(float2(0.52, 0.08) + float2(sin(t * 0.30 + 0.9), cos(t * 0.27 + 4.4)) * float2(0.20, 0.18), t * -0.08);
    float2 center4 = rotate2d(float2(-0.02, -0.32) + float2(cos(t * 0.24 + 5.1), sin(t * 0.21 + 1.9)) * float2(0.24, 0.16), t * 0.05);
    float2 center5 = rotate2d(float2(0.06, 0.34) + float2(sin(t * 0.19 + 2.8), cos(t * 0.23 + 3.2)) * float2(0.22, 0.16), t * -0.06);

    float f0 = blob(shapePoint, center0, float2(0.54, 0.86));
    float f1 = blob(shapePoint, center1, float2(0.50, 0.80));
    float f2 = blob(shapePoint, center2, float2(0.58, 0.88));
    float f3 = blob(shapePoint, center3, float2(0.50, 0.82));
    float f4 = blob(shapePoint, center4, float2(0.62, 0.74));
    float f5 = blob(shapePoint, center5, float2(0.64, 0.76));

    f0 = pow(max(f0, 0.0), colorSeparation);
    f1 = pow(max(f1, 0.0), colorSeparation);
    f2 = pow(max(f2, 0.0), colorSeparation);
    f3 = pow(max(f3, 0.0), colorSeparation);
    f4 = pow(max(f4, 0.0), colorSeparation);
    f5 = pow(max(f5, 0.0), colorSeparation);

    float total = f0 + f1 + f2 + f3 + f4 + f5;
    float weightSum = max(total, 0.001);
    float w0 = f0 / weightSum;
    float w1 = f1 / weightSum;
    float w2 = f2 / weightSum;
    float w3 = f3 / weightSum;
    float w4 = f4 / weightSum;
    float w5 = f5 / weightSum;

    float carrierA = fbm((shapePoint * 1.36) + float2(t * 0.06, -t * 0.05) + 11.0);
    float carrierB = fbm(rotate2d(shapePoint, -0.64) * 1.62 + float2(-t * 0.07, t * 0.09) + 17.0);
    float mixField = smoothstep(0.24, 0.82, carrierA * 0.58 + carrierB * 0.42);

    half3 rgb =
        (c0.rgb * half(w0)) +
        (c1.rgb * half(w1)) +
        (c2.rgb * half(w2)) +
        (c3.rgb * half(w3)) +
        (c4.rgb * half(w4)) +
        (c5.rgb * half(w5));

    half3 accent = mix(c6.rgb, c7.rgb, half(mixField));
    rgb = mix(rgb, accent, half(accentMixAmount));

    float highlightField = fbm((shapePoint * 2.10) + float2(t * 0.15, -t * 0.12) + 23.0);
    float highlight = smoothstep(0.80, 0.97, highlightField) * (0.10 * accentMixAmount);
    rgb += accent * half(highlight);

    float radialEnvelope = smoothstep(1.12 + (softness * 0.04), 0.02, length(shapePoint * float2(0.84, 0.92)));
    float alpha = clamp(smoothstep(0.22, 0.62, total) * radialEnvelope * intensity, 0.0, 1.0);
    half outAlpha = half(alpha);

    return half4(rgb, outAlpha);
}

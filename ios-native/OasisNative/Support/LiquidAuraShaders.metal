#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

static inline float soft_blob(float2 uv, float2 center, float2 radius) {
    float2 delta = (uv - center) / radius;
    float dist = dot(delta, delta);
    return exp(-dist * 2.8);
}

static inline float2 rotate2d(float2 point, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float2(
        (point.x * c) - (point.y * s),
        (point.x * s) + (point.y * c)
    );
}

[[ stitchable ]] half4 liquidSmoke(
    float2 position,
    half4 currentColor,
    float2 size,
    float time,
    half4 c0,
    half4 c1,
    half4 c2,
    float intensity
) {
    float2 safeSize = max(size, float2(1.0, 1.0));
    float2 uv = position / safeSize;
    float2 centered = uv - 0.5;
    float radius = length(centered);
    float rotation = (time * 0.22) + (radius * 1.2);
    float2 rotated = rotate2d(centered, rotation);

    float swirlA = sin((uv.y * 7.1) + (time * 1.34) + (radius * 6.0));
    float swirlB = cos((uv.x * 6.0) - (time * 1.08) - (radius * 5.2));
    float2 drift = float2(time * 0.008, time * -0.006);
    float2 flowedUV = 0.5 + (rotated * 0.82) + float2(swirlA * 0.016, swirlB * 0.012) + drift;

    float2 p0 = float2(
        0.32 + (0.12 * cos((time * 0.82) + 0.9)),
        0.48 + (0.08 * sin((time * 0.68) + 1.3))
    );
    float2 p1 = float2(
        0.56 + (0.10 * cos((time * 0.64) + 2.4)),
        0.44 + (0.10 * sin((time * 0.94) + 0.4))
    );
    float2 p2 = float2(
        0.73 + (0.11 * cos((time * 0.92) + 4.2)),
        0.56 + (0.09 * sin((time * 0.72) + 2.7))
    );

    float b0 = soft_blob(flowedUV, p0, float2(0.28, 0.72));
    float b1 = soft_blob(flowedUV, p1, float2(0.34, 0.82));
    float b2 = soft_blob(flowedUV, p2, float2(0.26, 0.68));

    float shimmer = 0.5 + (0.5 * sin((uv.x * 5.8) - (time * 1.1)));
    float pulse = 0.5 + (0.5 * sin((uv.x * 4.2) + (uv.y * 3.4) + (time * 1.4)));
    float density = clamp((b0 * 0.95) + (b1 * 0.9) + (b2 * 0.85), 0.0, 1.45);
    float alpha = clamp(density * intensity * (0.56 + (shimmer * 0.16) + (pulse * 0.10)), 0.0, 1.0);

    half3 rgb =
        (c0.rgb * half(b0)) +
        (c1.rgb * half(b1)) +
        (c2.rgb * half(b2));

    rgb *= half(0.84 - (density * 0.10));

    half outAlpha = half(alpha) * currentColor.a;
    return half4(rgb * outAlpha, outAlpha);
}

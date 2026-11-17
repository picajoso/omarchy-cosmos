#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    float uEnergy;
    vec4 uColorA;
    vec4 uColorB;
    vec4 uBg;
};

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    mat2 rot = mat2(0.80, -0.60, 0.60, 0.80);
    for (int i = 0; i < 5; ++i) {
        v += amp * noise(p);
        p = rot * p * 2.02 + vec2(1.7, 9.2);
        amp *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p = (uv - 0.5) * vec2(2.1, 2.3);

    float t = uTime * (0.22 + 0.28 * uEnergy);

    vec2 q;
    q.x = fbm(p + vec2(0.0, t * 0.65));
    q.y = fbm(p + vec2(5.2, 1.3 - t * 0.48));

    vec2 r;
    r.x = fbm(p + 3.4 * q + vec2(1.7, 9.2) + 0.35 * t);
    r.y = fbm(p + 3.4 * q + vec2(8.3, 2.8) - 0.28 * t);

    float f = fbm(p + 2.8 * r);

    // Silky aurora ribbons + edge caustics for Cosmos Aurora mode
    float ribbon1 = smoothstep(0.32, 0.88, f * f * 1.65 + 0.25 * r.x);
    float ribbon2 = smoothstep(0.45, 0.95, length(q) * 0.85);
    float edgeGlow = smoothstep(0.55, 1.15, abs(p.x) * 0.85) * f * 0.55;

    vec3 col = uBg.rgb;
    col = mix(col, uColorB.rgb, clamp(ribbon2 * 0.45, 0.0, 1.0));
    col = mix(col, uColorA.rgb, clamp(ribbon1 * (0.55 + 0.30 * uEnergy), 0.0, 1.0));
    col += (uColorA.rgb * 0.55 + uColorB.rgb * 0.45) * edgeGlow * (0.45 + 0.35 * uEnergy);

    // Smooth vertical fade at top & bottom so controls read cleanly
    float topFade = smoothstep(0.0, 0.16, uv.y);
    float botFade = 1.0 - 0.45 * smoothstep(0.62, 1.0, uv.y);
    col = mix(uBg.rgb, col, topFade * botFade);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}

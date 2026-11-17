#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 uColorA;
    vec4 uColorB;
    vec4 uColorC;
};

layout(binding = 1) uniform sampler2D glyphTex;

void main() {
    vec2 uv = qt_TexCoord0;
    float a = texture(glyphTex, uv).a;

    // Soft multi-tap ambient shadow behind the pixel-art blocks
    vec2 shOff = vec2(0.0, 0.018);
    float s = 0.0;
    s += texture(glyphTex, uv - shOff + vec2(-0.004, 0.0)).a;
    s += texture(glyphTex, uv - shOff + vec2( 0.004, 0.0)).a;
    s += texture(glyphTex, uv - shOff + vec2(0.0, -0.012)).a;
    s += texture(glyphTex, uv - shOff + vec2(0.0,  0.012)).a;
    s += texture(glyphTex, uv - shOff * 1.6).a;
    float shadow = (s / 5.0) * (1.0 - a) * 0.42;

    // Smooth 3-stop horizontal gradient with subtle vertical glass sheen
    float t = clamp(uv.x * 0.92 + (1.0 - uv.y) * 0.08, 0.0, 1.0);
    vec3 grad = (t < 0.5)
        ? mix(uColorA.rgb, uColorB.rgb, t * 2.0)
        : mix(uColorB.rgb, uColorC.rgb, (t - 0.5) * 2.0);

    // Subtle crisp top-pixel bevel highlight
    float aboveA = texture(glyphTex, uv - vec2(0.0, 0.009)).a;
    float topBevel = clamp(a - aboveA, 0.0, 1.0) * 0.18;
    vec3 glyphCol = clamp(grad + vec3(topBevel), 0.0, 1.0);

    // Premultiplied output for Qt Quick scenegraph
    vec3 premul = glyphCol * a;
    float outA = clamp(a + shadow, 0.0, 1.0);
    fragColor = vec4(premul, outA) * qt_Opacity;
}

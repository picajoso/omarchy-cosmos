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
    float alpha = texture(glyphTex, uv).a;
    vec3 grad = (uv.x < 0.52)
        ? mix(uColorA.rgb, uColorB.rgb, uv.x / 0.52)
        : mix(uColorB.rgb, uColorC.rgb, (uv.x - 0.52) / 0.48);
    fragColor = vec4(grad * alpha, alpha) * qt_Opacity;
}

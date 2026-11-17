#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    float uWorking;
    vec4 uAccent;
};

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
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
    float a = 0.5;
    mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);
    for (int i = 0; i < 4; ++i) {
        v += a * noise(p);
        p = rot * p * 2.03 + vec2(1.9, 7.3);
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = qt_TexCoord0;
    // Aspect-corrected coordinates (approx 340x420 -> ~0.81x1.0)
    vec2 p = vec2((uv.x - 0.5) * 0.84, uv.y - 0.5);

    // 1. Rich Twilight Cyber-Cosmos Sky Gradient
    vec3 skyTop = vec3(0.035, 0.055, 0.135);
    vec3 skyMid = vec3(0.085, 0.135, 0.275);
    vec3 skyHorizon = vec3(0.24, 0.15, 0.28) + uAccent.rgb * 0.12;
    vec3 skyWarm = vec3(0.42, 0.22, 0.18);

    vec3 col = mix(skyTop, skyMid, smoothstep(0.0, 0.45, uv.y));
    col = mix(col, skyHorizon, smoothstep(0.35, 0.68, uv.y));
    col = mix(col, skyWarm, smoothstep(0.54, 0.76, uv.y) * 0.55);

    // 2. Swirling Luminous Aurora & Nebula Curtains
    float t = uTime * (0.18 + 0.14 * uWorking);
    float n1 = fbm(vec2(uv.x * 3.4 + t * 0.35, uv.y * 2.6 - t * 0.2));
    float n2 = fbm(vec2(uv.x * 5.2 - t * 0.28, uv.y * 3.8 + n1 * 1.4));
    float curtain = smoothstep(0.36, 0.84, n2) * smoothstep(0.66, 0.08, uv.y);

    vec3 auroraA = mix(vec3(0.18, 0.82, 0.76), uAccent.rgb, 0.45);
    vec3 auroraB = vec3(0.54, 0.36, 0.96);
    col += mix(auroraA, auroraB, n1) * curtain * (0.48 + 0.18 * uWorking);

    // 3. Multi-layer Twinkling Starfield
    vec2 starGrid = uv * vec2(26.0, 32.0);
    vec2 sid = floor(starGrid);
    vec2 sf = fract(starGrid) - 0.5;
    float sh = hash21(sid);
    if (sh > 0.78 && uv.y < 0.58) {
        vec2 offset = vec2(fract(sh * 13.7) - 0.5, fract(sh * 29.3) - 0.5) * 0.6;
        float d = length(sf - offset);
        float twinkle = 0.55 + 0.45 * sin(uTime * (2.0 + sh * 4.0) + sh * 40.0);
        float star = smoothstep(0.11, 0.01, d) * twinkle;
        vec3 starCol = mix(vec3(1.0, 0.95, 0.88), vec3(0.65, 0.85, 1.0), fract(sh * 7.1));
        col += starCol * star * 0.95;
    }

    // 4. Ray-Shaded Ringed Gas-Giant Planet ("Cosmos") in upper-right sky
    vec2 planetCenter = vec2(0.20, -0.27);
    vec2 dp = p - planetCenter;
    float pr = 0.082;

    // Tilted coordinate space for planetary rings
    float ang = -0.36;
    mat2 rmat = mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
    vec2 rp = rmat * dp;
    vec2 ringEll = vec2(rp.x * 0.44, rp.y * 2.05);
    float ringDist = length(ringEll);
    float ringBand = smoothstep(pr * 0.62, pr * 0.70, ringDist) * smoothstep(pr * 1.18, pr * 1.02, ringDist);
    float ringCassini = 1.0 - 0.65 * smoothstep(pr * 0.88, pr * 0.91, ringDist) * smoothstep(pr * 0.95, pr * 0.92, ringDist);
    vec3 ringCol = mix(vec3(0.96, 0.84, 0.66), vec3(0.62, 0.78, 0.98), smoothstep(pr * 0.65, pr * 1.15, ringDist));

    // Back half of rings (behind planet)
    if (rp.y < 0.0 && ringBand > 0.001) {
        col = mix(col, ringCol, ringBand * ringCassini * 0.55);
    }

    // 3D Sphere shading for the planet
    float distP = length(dp);
    if (distP < pr) {
        vec2 sn = dp / pr;
        float sz = sqrt(max(0.0, 1.0 - dot(sn, sn)));
        vec3 normal = normalize(vec3(sn, sz));
        vec3 lightDir = normalize(vec3(-0.65, -0.55, 0.52));
        float diff = max(0.0, dot(normal, lightDir));
        float bands = 0.5 + 0.5 * sin(rp.y * 95.0 + fbm(sn * 4.0) * 3.0);
        vec3 pDay = mix(vec3(0.98, 0.82, 0.58), vec3(0.76, 0.52, 0.78), bands * 0.55);
        vec3 pNight = vec3(0.06, 0.08, 0.18);
        vec3 pCol = mix(pNight, pDay, pow(diff, 0.75));
        // Atmospheric Fresnel rim glow
        float rim = pow(1.0 - sz, 3.0);
        pCol += vec3(0.45, 0.78, 1.0) * rim * 0.65;
        float edgeAA = smoothstep(pr, pr - 0.004, distP);
        col = mix(col, pCol, edgeAA);
    } else {
        // Soft atmospheric halo outside planet
        float halo = exp(-max(0.0, distP - pr) * 26.0);
        col += vec3(0.65, 0.75, 1.0) * halo * 0.22;
    }

    // Front half of rings (crossing in front of planet)
    if (rp.y >= 0.0 && ringBand > 0.001) {
        col = mix(col, ringCol, ringBand * ringCassini * 0.82);
    }

    // 5. Distant Cyberpunk Skyline Silhouette & Glowing Window Bokeh
    float cityBase = 0.66;
    float bx = floor(uv.x * 22.0);
    float bh = hash21(vec2(bx, 4.2));
    float bTop = cityBase - (0.04 + 0.14 * bh * bh);
    if (uv.y > bTop && uv.y < cityBase + 0.06) {
        vec3 bldgCol = vec3(0.055, 0.068, 0.125);
        // Tiny lit skyscraper windows
        vec2 wGrid = fract(uv * vec2(88.0, 115.0));
        vec2 wId = floor(uv * vec2(88.0, 115.0));
        float wh = hash21(wId);
        float winMask = step(0.25, wGrid.x) * step(wGrid.x, 0.75) * step(0.22, wGrid.y) * step(wGrid.y, 0.72);
        if (wh > 0.68 && uv.y > bTop + 0.008) {
            vec3 winCol = (wh > 0.88) ? vec3(0.25, 0.88, 0.95) : vec3(1.0, 0.76, 0.38);
            float flicker = 0.75 + 0.25 * sin(uTime * 1.5 + wh * 30.0);
            bldgCol = mix(bldgCol, winCol * flicker, winMask * 0.85);
        }
        col = mix(col, bldgCol, smoothstep(bTop, bTop + 0.004, uv.y));
    }

    // 6. Warm Volumetric Lamp / Window God-Rays slanting from upper-left
    float rayCoord = uv.x * 0.85 - uv.y * 0.42;
    float rays = 0.5 + 0.5 * sin(rayCoord * 18.0);
    float rayMask = smoothstep(0.85, 0.05, uv.y) * smoothstep(0.95, 0.05, uv.x);
    col += vec3(1.0, 0.76, 0.42) * pow(rays, 3.0) * rayMask * 0.09;

    fragColor = vec4(col, 1.0) * qt_Opacity;
}

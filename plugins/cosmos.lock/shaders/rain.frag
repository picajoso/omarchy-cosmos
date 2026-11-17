#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    float uAspect;
    float uIntensity;
};

layout(binding = 1) uniform sampler2D sharpTex;
layout(binding = 2) uniform sampler2D mistTex;

vec3 hash13(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

// Stationary condensation droplets resting on the window pane (isotropic p-space)
// Returns vec3(normal.x, normal.y, mask)
vec3 staticBeadLayer(vec2 p, float t, float freq, float densityCutoff) {
    vec2 st = p * freq;
    vec2 id = floor(st);
    vec2 gv = fract(st) - 0.5;

    vec3 h = hash13(id.x * 113.5 + id.y * 471.3 + freq * 13.7);
    if (h.x < densityCutoff) {
        return vec3(0.0);
    }

    vec2 center = (h.xy - 0.5) * 0.54;
    vec2 d = gv - center;

    // Slight organic asymmetry per resting bead
    float ang = atan(d.y, d.x);
    float baseR = mix(0.065, 0.23, h.z * h.z);
    float r = max(0.01, baseR * (1.0 + 0.10 * sin(ang * 3.0 + h.y * 6.2831)));

    // Slow gentle condensation/evaporation cycle
    float cycle = fract(t * 0.035 + h.z);
    float fade = smoothstep(0.0, 0.18, cycle) * smoothstep(1.0, 0.78, cycle);

    float dist = length(d);
    float mask = smoothstep(r, r * 0.64, dist) * fade;
    vec2 normal = (mask > 0.001) ? (d / r) * mask : vec2(0.0);
    return vec3(normal, mask);
}

// Gravity-driven stick-slip sliding raindrops + stationary wake beadlets
// p is isotropic screen-height space: vec2(uv.x * uAspect, uv.y)
// Returns vec4(normal.x, normal.y, dropMask, wipedTrailMask)
vec4 slidingDropLayer(vec2 p, float t, float scale, float densityCutoff) {
    vec2 grid = vec2(6.8, 2.35) * scale;
    vec2 st = p * grid;

    float colId = floor(st.x);
    float colSeed = hash21(vec2(colId, scale * 19.37));

    // Subtracting time scrolls cells smoothly DOWNWARD on screen (increasing p.y)
    float colSpeed = 0.19 + 0.16 * colSeed;
    st.y -= t * colSpeed + colSeed * 9.7;

    vec2 id = floor(st);
    vec2 gv = fract(st);

    vec3 n = hash13(id.x * 157.31 + id.y * 789.17 + scale * 41.0);
    if (n.x < densityCutoff) {
        return vec4(0.0);
    }

    // Horizontal meander + smooth periodic stick-slip hesitation (never hits cell edges!)
    float w = p.y * 8.5 + n.x * 6.2831;
    float xPos = 0.5 + (n.x - 0.5) * 0.42 + sin(w + sin(w) * 0.55) * 0.055;

    float slipArg = t * (1.35 + 0.55 * n.y) + n.y * 6.2831;
    float slip = sin(slipArg + sin(slipArg) * 0.62) * 0.15;
    float yPos = 0.54 + slip;

    // Convert cell delta back into TRUE isotropic physical distance
    vec2 d = (gv - vec2(xPos, yPos)) / grid;

    // Physical bead radius (in screen-height fractions)
    float r = mix(0.0055, 0.0145, n.z * n.z) / sqrt(scale);

    // Organic teardrop meniscus: slightly fuller bottom belly (d.y > 0), tapered top tail (d.y < 0)
    vec2 shapeD = d;
    float taper = clamp(-d.y / max(0.002, r * 1.75), 0.0, 1.0);
    shapeD.x *= 1.0 + taper * 0.52;
    shapeD.y *= (d.y < 0.0) ? 0.76 : 1.10;

    float angle = atan(shapeD.y, shapeD.x);
    float organicR = max(0.0008, r * (1.0 + 0.08 * sin(angle * 3.0 + n.x * 6.2831) + 0.05 * cos(angle * 5.0 - n.y * 6.2831)));

    float dist = length(shapeD);
    float mainDrop = smoothstep(organicR, organicR * 0.68, dist);

    // Wiped condensation channel above the sliding bead (d.y < 0 is above on screen)
    float maxTrail = 0.125 / sqrt(scale);
    float trailAlong = smoothstep(maxTrail, r * 0.8, -d.y) * smoothstep(0.0, r * 1.1, -d.y);
    float trailAcross = smoothstep(r * 1.25, r * 0.15, abs(d.x));
    float wipedTrail = trailAlong * trailAcross;

    // Tiny stationary wake beadlets left behind along the wiped track (anchored to p.y!)
    float beadFreq = 54.0 * sqrt(scale);
    float beadId = floor(p.y * beadFreq);
    float beadSeed = hash21(vec2(id.x * 17.3 + scale * 11.0, beadId));
    float beadLocalY = (fract(p.y * beadFreq) - 0.5) / beadFreq;
    vec2 wakeVec = vec2(d.x + (beadSeed - 0.5) * r * 0.38, beadLocalY);

    float wakeEnv = smoothstep(maxTrail * 0.92, r * 1.3, -d.y) * smoothstep(r * 0.95, r * 1.65, -d.y);
    float wakeR = r * mix(0.18, 0.44, beadSeed) * sqrt(max(0.0, wakeEnv));

    float wakeDrop = 0.0;
    if (wakeR > 0.00055 && beadSeed > 0.34) {
        wakeDrop = smoothstep(wakeR, wakeR * 0.62, length(wakeVec));
    }

    float combinedMask = max(mainDrop, wakeDrop);
    vec2 normal = vec2(0.0);
    if (mainDrop >= wakeDrop && mainDrop > 0.001) {
        normal = (shapeD / organicR) * mainDrop;
    } else if (wakeDrop > 0.001) {
        normal = (wakeVec / max(0.0006, wakeR)) * wakeDrop * 0.85;
    }

    return vec4(normal, combinedMask, wipedTrail);
}

void main() {
    vec2 uv = qt_TexCoord0;

    if (uIntensity <= 0.01) {
        vec3 base = texture(sharpTex, uv).rgb;
        float lowerVig = smoothstep(0.58, 1.0, uv.y) * smoothstep(0.75, 0.0, uv.x);
        fragColor = vec4(base * (1.0 - 0.28 * lowerVig), 1.0) * qt_Opacity;
        return;
    }

    vec2 p = vec2(uv.x * uAspect, uv.y);
    float isDownpour = step(1.5, uIntensity);
    float speedMul = mix(1.0, 1.55, clamp(uIntensity - 1.0, 0.0, 1.0));
    float t = uTime * speedMul;

    // Two scales of resting micro-droplets across the window
    vec3 microFine = staticBeadLayer(p, uTime, 56.0, mix(0.46, 0.24, isDownpour));
    vec3 microMed  = staticBeadLayer(p + vec2(1.73, 0.89), uTime * 0.8, 25.0, mix(0.58, 0.34, isDownpour));

    // Two (Drizzle) or three (Downpour) sliding gravity raindrop layers
    vec4 slideHero = slidingDropLayer(p, t, 1.0, mix(0.32, 0.16, isDownpour));
    vec4 slideMid  = slidingDropLayer(p + vec2(2.41, 0.63), t * 1.24, 1.75, mix(0.30, 0.14, isDownpour));
    vec4 slideFast = (isDownpour > 0.5)
        ? slidingDropLayer(p + vec2(5.17, 1.94), t * 1.58, 2.65, 0.20)
        : vec4(0.0);

    // Layer priority composition so foreground hero beads cleanly absorb smaller micro-beads
    vec2 dropNormal = microFine.xy * 0.52 + microMed.xy * 0.72;
    float dropMask = max(microFine.z * 0.82, microMed.z * 0.92);

    float wiped = clamp(slideHero.w + slideMid.w + slideFast.w, 0.0, 1.0);
    // Wiped channels clear away resting micro-condensation
    dropNormal *= (1.0 - wiped * 0.85);
    dropMask   *= (1.0 - wiped * 0.85);

    if (slideFast.z > 0.001) {
        dropNormal = mix(dropNormal, slideFast.xy, slideFast.z);
        dropMask = max(dropMask, slideFast.z);
    }
    if (slideMid.z > 0.001) {
        dropNormal = mix(dropNormal, slideMid.xy, slideMid.z);
        dropMask = max(dropMask, slideMid.z);
    }
    if (slideHero.z > 0.001) {
        dropNormal = mix(dropNormal, slideHero.xy, slideHero.z);
        dropMask = max(dropMask, slideHero.z);
    }

    dropMask = clamp(dropMask, 0.0, 1.0);

    // Wet window background: subtle misty glass outside drops, clearer along wiped trails
    vec3 mistyBg = texture(mistTex, uv).rgb * 0.96;
    vec3 sharpBg = texture(sharpTex, uv).rgb;
    vec3 windowBg = mix(mistyBg, sharpBg, wiped * 0.72);

    // Convex water-bead optical refraction (inverts & magnifies surrounding wallpaper)
    float normLen = clamp(length(dropNormal), 0.0, 1.25);
    vec2 refractOffset = dropNormal * (0.055 + 0.035 * normLen);
    vec2 refractedUv = clamp(uv - refractOffset, vec2(0.002), vec2(0.998));
    vec3 refractedCol = texture(sharpTex, refractedUv).rgb * 1.05;

    // Realistic meniscus optics: dark total-internal-reflection rim + crisp specular highlight + lower caustic glow
    float rimDark = smoothstep(0.52, 0.98, normLen) * 0.34;
    vec3 n3 = normalize(vec3(dropNormal * 1.55, max(0.28, 1.0 - min(0.82, normLen))));
    vec3 lightDir = normalize(vec3(-0.38, -0.68, 0.62));
    float spec = pow(max(0.0, dot(n3, lightDir)), 26.0) * dropMask;
    float bottomCaustic = clamp(dropNormal.y * 0.55, 0.0, 0.32) * (1.0 - rimDark) * dropMask;

    vec3 beadCol = refractedCol * (1.0 - rimDark) + vec3(0.95, 0.97, 1.0) * bottomCaustic * 0.28;
    vec3 col = mix(windowBg, beadCol, dropMask);
    col += vec3(1.0, 0.99, 0.96) * spec * 0.52;

    // Subtle lower-left vignette so the gradient clock & status remain effortless to read
    float lowerVig = smoothstep(0.56, 1.0, uv.y) * smoothstep(0.72, 0.0, uv.x);
    col *= (1.0 - 0.32 * lowerVig);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}

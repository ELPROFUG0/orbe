//
//  DropletShader.metal
//  orbe
//
//  Droplet shader with wavy border distortion
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Noise functions
float hash2D(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float noise2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash2D(i);
    float b = hash2D(i + float2(1.0, 0.0));
    float c = hash2D(i + float2(0.0, 1.0));
    float d = hash2D(i + float2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm2D(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise2D(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Distortion effect - distorts the shape of the view (wavy border)
[[ stitchable ]] float2 wavyDistortion(
    float2 position,
    float2 size,
    float time,
    float motionSpeed,
    float motionStrength,
    float motionFrequency,
    float motionNoise
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 delta = uv - center;
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x);

    // Base radius
    float radius = 0.5;

    if (motionStrength < 0.001) {
        return position;
    }

    // === WAVY BORDER DISTORTION ===
    // Multiple wave frequencies for organic look
    float wave1 = sin(angle * motionFrequency * 8.0 + time * motionSpeed * 4.0) * motionStrength * 0.15;
    float wave2 = sin(angle * motionFrequency * 12.0 - time * motionSpeed * 6.0) * motionStrength * 0.08;
    float wave3 = sin(angle * motionFrequency * 5.0 + time * motionSpeed * 2.5) * motionStrength * 0.12;

    // Noise-based organic distortion
    float noiseAngle = angle + time * motionSpeed * 0.5;
    float noiseWave = (fbm2D(float2(noiseAngle * 2.0, time * motionSpeed)) - 0.5) * motionNoise * motionStrength * 0.2;

    // Combine all waves
    float totalWave = wave1 + wave2 + wave3 + noiseWave;

    // Apply wave distortion - stronger at edges
    float edgeFactor = smoothstep(0.0, 1.0, dist / radius);
    float2 waveOffset = normalize(delta + 0.0001) * totalWave * edgeFactor;

    // Also add some internal ripple
    float ripple = sin(dist * motionFrequency * 20.0 - time * motionSpeed * 5.0);
    ripple *= motionStrength * (1.0 - edgeFactor) * 0.03;
    float2 rippleOffset = normalize(delta + 0.0001) * ripple;

    float2 newPos = position + (waveOffset + rippleOffset) * size;

    return newPos;
}

// Layer effect - fisheye lens and visual effects
[[ stitchable ]] half4 dropletEffect(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float motionSpeed,
    float motionStrength,
    float motionFrequency,
    float motionNoise,
    float lightIntensity,
    float edgeIntensity,
    float lensIntensity,
    float reflectionIntensity
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 delta = uv - center;
    float dist = length(delta);
    float radius = 0.5;

    // Outside orb - transparent
    if (dist > radius * 1.1) {
        return half4(0.0);
    }

    float normalizedDist = dist / radius;
    float angle = atan2(delta.y, delta.x);

    // === LENS DISTORTION ===
    float newDist = normalizedDist;

    if (lensIntensity > 0.001) {
        // === EDGE REFRACTION - stretch image at borders ===
        // This creates the "water droplet" effect where colors bleed outward at edges
        // Starts at 85% of radius, maximum effect at the very edge
        float edgeZone = smoothstep(0.85, 1.0, normalizedDist);

        // Subtle fisheye only in the center (reduced effect)
        float power = 1.0 + lensIntensity * 0.5 * (1.0 - edgeZone);
        newDist = pow(normalizedDist, power);

        // Strong stretch at the edge - samples from further inside
        if (edgeZone > 0.0) {
            float stretchFactor = 1.0 - edgeZone * lensIntensity * 0.6;
            newDist *= stretchFactor;
        }
    }

    float2 distortedDelta = float2(cos(angle), sin(angle)) * newDist * radius;
    float2 sampleUV = center + distortedDelta;

    // === INTERNAL MOTION RIPPLES ===
    if (motionStrength > 0.001) {
        float ripple = sin(normalizedDist * motionFrequency * 25.0 - time * motionSpeed * 6.0);
        ripple *= motionStrength * (1.0 - normalizedDist) * 0.04;

        float2 noiseCoord = sampleUV * 4.0 + float2(time * motionSpeed * 0.4);
        float noiseVal = (fbm2D(noiseCoord) - 0.5) * motionNoise * motionStrength * 0.03;

        float2 dir = normalize(delta + 0.0001);
        sampleUV += dir * (ripple + noiseVal);
    }

    sampleUV = clamp(sampleUV, float2(0.001), float2(0.999));
    float2 samplePos = sampleUV * size;
    half4 color = layer.sample(samplePos);

    // === LIGHT - contrast adjustment ===
    if (lightIntensity > 0.001) {
        // Increase contrast: (color - 0.5) * contrast + 0.5
        float contrast = 1.0 + lightIntensity * 0.8;
        color.rgb = half3(clamp((float3(color.rgb) - 0.5) * contrast + 0.5, 0.0, 1.0));
    }

    // === REFLECTION - saturate colors at edges ===
    if (reflectionIntensity > 0.001) {
        // Only apply at the edges (outer 15% of radius)
        float reflectEdge = smoothstep(0.85, 1.0, normalizedDist);

        if (reflectEdge > 0.0) {
            // Calculate luminance
            float lum = dot(float3(color.rgb), float3(0.299, 0.587, 0.114));

            // Increase saturation by moving away from gray
            float satBoost = 1.0 + reflectEdge * reflectionIntensity * 1.5;
            half3 saturatedColor = half3(mix(float3(lum), float3(color.rgb), satBoost));

            // Also boost brightness slightly
            saturatedColor *= half(1.0 + reflectEdge * reflectionIntensity * 0.3);

            color.rgb = saturatedColor;
        }
    }

    return color;
}

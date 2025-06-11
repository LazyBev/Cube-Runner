#ifdef GL_ES
precision mediump float;
#endif

extern Image tex0;
extern vec2 dimensions;
extern float time;
extern float bloomIntensity;
extern float bloomThreshold;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 pixel = Texel(tex, tc);
    
    // Calculate brightness
    float brightness = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
    
    // Apply bloom threshold
    if (brightness > bloomThreshold) {
        // Create bloom effect
        float bloom = smoothstep(bloomThreshold, 1.0, brightness) * bloomIntensity;
        
        // Add subtle pulsing
        float pulse = sin(time * 2.0) * 0.1 + 0.9;
        bloom *= pulse;
        
        // Mix original color with bloom
        pixel.rgb = mix(pixel.rgb, pixel.rgb * 1.5, bloom);
    }
    
    return pixel;
} 
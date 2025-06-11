#ifdef GL_ES
precision mediump float;
#endif

extern Image tex0;
extern vec2 dimensions;
extern float time;
extern vec3 glowColor;
extern float intensity;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 pixel = Texel(tex, tc);
    
    // Calculate distance from center
    vec2 center = dimensions * 0.5;
    float dist = length(sc - center) / (dimensions.x * 0.5);
    
    // Create glow effect
    float glow = 1.0 - smoothstep(0.0, 1.0, dist);
    glow = pow(glow, 2.0) * intensity;
    
    // Add subtle pulsing
    float pulse = sin(time * 2.0) * 0.1 + 0.9;
    glow *= pulse;
    
    // Mix original color with glow
    vec3 finalColor = mix(pixel.rgb, glowColor, glow);
    
    return vec4(finalColor, pixel.a);
} 
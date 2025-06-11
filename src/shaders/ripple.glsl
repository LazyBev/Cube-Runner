#ifdef GL_ES
precision mediump float;
#endif

extern Image tex0;
extern vec2 dimensions;
extern float time;
extern vec2 mousePos;
extern float rippleStrength;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    // Calculate distance from mouse position
    float dist = length(sc - mousePos) / dimensions.x;
    
    // Create ripple effect
    float ripple = sin(dist * 20.0 - time * 5.0) * rippleStrength;
    ripple *= exp(-dist * 2.0); // Fade out with distance
    
    // Apply ripple to texture coordinates
    vec2 offset = vec2(ripple);
    vec4 pixel = Texel(tex, tc + offset);
    
    return pixel;
} 
local PostProcess = love.graphics.newShader[[
    extern number time;
    extern number bloomIntensity;
    extern number vignetteIntensity;
    extern number chromaticAberration;
    extern number colorGrade;
    
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        // Base color
        vec4 pixel = Texel(tex, tc);
        
        // Bloom effect
        vec4 bloom = vec4(0.0);
        for(float i = -4.0; i <= 4.0; i += 1.0) {
            for(float j = -4.0; j <= 4.0; j += 1.0) {
                vec2 offset = vec2(i, j) * 0.002;
                bloom += Texel(tex, tc + offset) * 0.025;
            }
        }
        pixel += bloom * bloomIntensity;
        
        // Vignette
        vec2 center = vec2(0.5, 0.5);
        float dist = distance(tc, center);
        float vignette = smoothstep(0.5, 0.2, dist);
        pixel.rgb *= mix(1.0, vignette, vignetteIntensity);
        
        // Chromatic aberration
        float r = Texel(tex, tc + vec2(chromaticAberration, 0.0)).r;
        float g = Texel(tex, tc).g;
        float b = Texel(tex, tc - vec2(chromaticAberration, 0.0)).b;
        pixel.rgb = mix(pixel.rgb, vec3(r, g, b), chromaticAberration);
        
        // Color grading
        if(colorGrade > 0.0) {
            // Warm tone
            pixel.r *= 1.1;
            pixel.g *= 0.95;
            pixel.b *= 0.9;
            
            // Slight contrast boost
            pixel.rgb = (pixel.rgb - 0.5) * 1.1 + 0.5;
        }
        
        // Subtle scanlines
        float scanline = sin(tc.y * 800.0) * 0.02;
        pixel.rgb += vec3(scanline);
        
        // Subtle noise
        float noise = fract(sin(dot(tc, vec2(12.9898, 78.233))) * 43758.5453);
        pixel.rgb += vec3(noise * 0.02);
        
        return pixel;
    }
]]

-- Initialize shader parameters
PostProcess:send("bloomIntensity", 0.5)
PostProcess:send("vignetteIntensity", 0.3)
PostProcess:send("chromaticAberration", 0.002)
PostProcess:send("colorGrade", 1.0)

return PostProcess 
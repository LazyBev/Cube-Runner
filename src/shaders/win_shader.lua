local shader = love.graphics.newShader[[
    extern float time;
    extern vec2 resolution;
    extern vec3 winnerColor;
    extern float intensity;

    float random(vec2 st) {
        return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
    }

    float noise(vec2 st) {
        vec2 i = floor(st);
        vec2 f = fract(st);
        
        float a = random(i);
        float b = random(i + vec2(1.0, 0.0));
        float c = random(i + vec2(0.0, 1.0));
        float d = random(i + vec2(1.0, 1.0));

        vec2 u = f * f * (3.0 - 2.0 * f);
        return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
    }

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = screen_coords / resolution;
        
        // Create dynamic pattern
        float pattern = 0.0;
        for(float i = 1.0; i < 4.0; i++) {
            pattern += noise(uv * (i * 10.0) + time * 0.5) * (1.0 / i);
        }
        
        // Create radial gradient
        vec2 center = vec2(0.5, 0.5);
        float dist = length(uv - center);
        float radial = 1.0 - smoothstep(0.0, 0.5, dist);
        
        // Create wave effect
        float wave = sin(uv.x * 10.0 + time) * 0.5 + 0.5;
        wave *= sin(uv.y * 8.0 + time * 0.8) * 0.5 + 0.5;
        
        // Combine effects
        vec3 finalColor = mix(winnerColor, vec3(1.0), pattern * intensity);
        finalColor = mix(finalColor, vec3(1.0), wave * 0.3);
        finalColor *= radial;
        
        // Add pulsing glow
        float pulse = sin(time * 2.0) * 0.5 + 0.5;
        finalColor += winnerColor * pulse * 0.2;
        
        return vec4(finalColor, 1.0);
    }
]]

return shader 
local Shaders = {}

-- Common uniforms for all shaders
local time = 0
function Shaders.update(dt)
    time = time + dt
end

-- Shader effects
local effects = {
    bloom = nil,
    glow = nil,
    ripple = nil,
    cardGlow = nil,
    balatroBg = nil
}

-- Shader code
local shaderCode = {
    cardGlow = [[
        extern Image tex0;
        extern vec2 dimensions;
        extern float time;
        extern vec3 glowColor;
        extern float intensity;
        extern float pulseSpeed;
        extern float noiseScale;

        // Simplex noise function
        vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

        float snoise(vec2 v) {
            const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                                -0.577350269189626, 0.024390243902439);
            vec2 i  = floor(v + dot(v, C.yy));
            vec2 x0 = v -   i + dot(i, C.xx);
            vec2 i1;
            i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
            vec4 x12 = x0.xyxy + C.xxzz;
            x12.xy -= i1;
            i = mod289(i);
            vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0));
            vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy),
                dot(x12.zw, x12.zw)), 0.0);
            m = m*m;
            m = m*m;
            vec3 x = 2.0 * fract(p * C.www) - 1.0;
            vec3 h = abs(x) - 0.5;
            vec3 ox = floor(x + 0.5);
            vec3 a0 = x - ox;
            m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
            vec3 g;
            g.x  = a0.x  * x0.x  + h.x  * x0.y;
            g.yz = a0.yz * x12.xz + h.yz * x12.yw;
            return 130.0 * dot(m, g);
        }

        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
            vec4 pixel = Texel(tex, tc);
            
            // Calculate distance from center
            vec2 center = dimensions * 0.5;
            float dist = length(sc - center) / (dimensions.x * 0.5);
            
            // Create noise-based glow
            float noise = snoise(sc * noiseScale + time * 0.5) * 0.5 + 0.5;
            float glow = 1.0 - smoothstep(0.0, 1.0, dist);
            glow = pow(glow, 2.0) * intensity;
            
            // Add pulsing effect
            float pulse = sin(time * pulseSpeed) * 0.1 + 0.9;
            glow *= pulse;
            
            // Add noise variation
            glow *= (0.8 + noise * 0.4);
            
            // Mix original color with glow
            vec3 finalColor = mix(pixel.rgb, glowColor, glow);
            
            // Add subtle color variation based on noise
            finalColor += noise * 0.1 * glowColor;
            
            return vec4(finalColor, pixel.a);
        }
    ]],
    
    balatroBg = [[
        extern float time;
        extern vec2 dimensions;
        extern vec3 primaryColor;
        extern vec3 secondaryColor;
        extern float noiseScale;
        extern float speed;

        // Simplex noise function (same as cardGlow)
        vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

        float snoise(vec2 v) {
            const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                                -0.577350269189626, 0.024390243902439);
            vec2 i  = floor(v + dot(v, C.yy));
            vec2 x0 = v -   i + dot(i, C.xx);
            vec2 i1;
            i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
            vec4 x12 = x0.xyxy + C.xxzz;
            x12.xy -= i1;
            i = mod289(i);
            vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0));
            vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy),
                dot(x12.zw, x12.zw)), 0.0);
            m = m*m;
            m = m*m;
            vec3 x = 2.0 * fract(p * C.www) - 1.0;
            vec3 h = abs(x) - 0.5;
            vec3 ox = floor(x + 0.5);
            vec3 a0 = x - ox;
            m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
            vec3 g;
            g.x  = a0.x  * x0.x  + h.x  * x0.y;
            g.yz = a0.yz * x12.xz + h.yz * x12.yw;
            return 130.0 * dot(m, g);
        }

        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
            // Create animated noise pattern
            float noise1 = snoise(sc * noiseScale + time * speed) * 0.5 + 0.5;
            float noise2 = snoise(sc * noiseScale * 2.0 - time * speed * 0.5) * 0.5 + 0.5;
            
            // Create gradient based on position
            vec2 center = dimensions * 0.5;
            float dist = length(sc - center) / (dimensions.x * 0.5);
            float gradient = 1.0 - smoothstep(0.0, 1.0, dist);
            
            // Mix colors based on noise and gradient
            vec3 color1 = mix(primaryColor, secondaryColor, noise1);
            vec3 color2 = mix(secondaryColor, primaryColor, noise2);
            vec3 finalColor = mix(color1, color2, gradient);
            
            // Add subtle pulsing
            float pulse = sin(time * 0.5) * 0.1 + 0.9;
            finalColor *= pulse;
            
            // Add noise-based variation
            finalColor += (noise1 + noise2) * 0.1;
            
            return vec4(finalColor, 1.0);
        }
    ]]
}

function Shaders.init()
    -- Load shaders
    effects.bloom = love.graphics.newShader(shaderCode.bloom)
    effects.glow = love.graphics.newShader(shaderCode.glow)
    effects.ripple = love.graphics.newShader(shaderCode.ripple)
    effects.cardGlow = love.graphics.newShader(shaderCode.cardGlow)
    effects.balatroBg = love.graphics.newShader(shaderCode.balatroBg)
    
    -- Create canvas for post-processing
    ShaderManager.canvas = love.graphics.newCanvas()
    
    -- Initialize shader uniforms
    local w, h = love.graphics.getDimensions()
    
    -- Card glow shader uniforms
    effects.cardGlow:send("time", 0)
    effects.cardGlow:send("glowColor", {1, 1, 1})
    effects.cardGlow:send("intensity", 0.5)
    effects.cardGlow:send("pulseSpeed", 2.0)
    effects.cardGlow:send("noiseScale", 0.01)
    
    -- Balatro background shader uniforms
    effects.balatroBg:send("time", 0)
    effects.balatroBg:send("primaryColor", {0.1, 0.1, 0.2})
    effects.balatroBg:send("secondaryColor", {0.2, 0.2, 0.3})
    effects.balatroBg:send("noiseScale", 0.005)
    effects.balatroBg:send("speed", 0.2)
end

function Shaders.update(dt)
    time = time + dt
    
    -- Update shader time
    effects.cardGlow:send("time", time)
    effects.balatroBg:send("time", time)
end

function Shaders.applyCardGlow(drawFunc, color, intensity)
    love.graphics.setCanvas(ShaderManager.canvas)
    love.graphics.clear()
    drawFunc()
    love.graphics.setCanvas()
    
    effects.cardGlow:send("glowColor", color)
    effects.cardGlow:send("intensity", intensity)
    love.graphics.setShader(effects.cardGlow)
    love.graphics.draw(ShaderManager.canvas)
    love.graphics.setShader()
end

function Shaders.applyBalatroBg(drawFunc)
    love.graphics.setCanvas(ShaderManager.canvas)
    love.graphics.clear()
    drawFunc()
    love.graphics.setCanvas()
    
    love.graphics.setShader(effects.balatroBg)
    love.graphics.draw(ShaderManager.canvas)
    love.graphics.setShader()
end

-- Cyberpunk screen effect with scanlines, glitch, and neon bloom
Shaders.cyberpunkScreen = love.graphics.newShader[[
    extern float time;
    extern vec2 resolution;
    extern float intensity;
    
    // Noise function
    float random(vec2 st) {
        return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
    }
    
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(tex, texture_coords);
        vec2 uv = screen_coords / resolution;
        
        // Scanlines
        float scanline = sin(uv.y * 800.0) * 0.04 + 0.96;
        
        // Glitch effect
        float glitch = 0.0;
        if (random(vec2(time * 0.1, uv.y)) > 0.99) {
            glitch = random(vec2(time)) * 0.1;
            uv.x += glitch;
        }
        
        // Color shift
        vec4 r = Texel(tex, vec2(uv.x + 0.01, uv.y));
        vec4 g = Texel(tex, uv);
        vec4 b = Texel(tex, vec2(uv.x - 0.01, uv.y));
        
        // Neon bloom
        vec4 bloom = vec4(0.0);
        for(float i = 0.0; i < 5.0; i++) {
            float offset = i * 0.002;
            bloom += Texel(tex, vec2(uv.x + offset, uv.y));
            bloom += Texel(tex, vec2(uv.x - offset, uv.y));
            bloom += Texel(tex, vec2(uv.x, uv.y + offset));
            bloom += Texel(tex, vec2(uv.x, uv.y - offset));
        }
        bloom /= 20.0;
        
        // Vignette
        float vignette = 1.0 - length(uv - 0.5) * 2.0;
        vignette = smoothstep(0.0, 0.7, vignette);
        
        // Combine effects
        vec4 final = vec4(r.r, g.g, b.b, pixel.a);
        final = mix(final, bloom, 0.3);
        final *= scanline * vignette;
        
        // Add subtle noise
        final += random(uv + time) * 0.02;
        
        return final;
    }
]]

-- Cyberpunk void trail effect
Shaders.voidTrail = love.graphics.newShader[[
    extern float time;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(tex, texture_coords);
        float alpha = pixel.a * color.a;
        
        // Cyberpunk void effect
        float pulse = sin(time * 3.0) * 0.5 + 0.5;
        vec3 voidColor = vec3(0.0, 0.8, 1.0) * (1.0 + pulse * 0.2);
        
        // Add digital distortion
        float distortion = sin(screen_coords.x * 0.1 + time * 2.0) * 0.02;
        alpha *= 1.0 + distortion;
        
        // Add neon glow
        float glow = sin(time * 4.0 + screen_coords.x * 0.1) * 0.5 + 0.5;
        voidColor += vec3(0.0, 1.0, 1.0) * glow * 0.3;
        
        // Add scanlines
        float scanline = sin(screen_coords.y * 0.1) * 0.5 + 0.5;
        alpha *= scanline * 0.8 + 0.2;
        
        return vec4(voidColor, alpha);
    }
]]

-- Cyberpunk fire trail effect
Shaders.fireTrail = love.graphics.newShader[[
    extern float time;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(tex, texture_coords);
        float alpha = pixel.a * color.a;
        
        // Cyberpunk fire colors
        vec3 fireColor = vec3(1.0, 0.0, 0.8); // Hot pink
        float flameIntensity = sin(time * 5.0 + screen_coords.y * 0.1) * 0.5 + 0.5;
        
        // Add purple and blue highlights
        fireColor += vec3(0.8, 0.0, 1.0) * flameIntensity * 0.5;
        fireColor += vec3(0.0, 0.5, 1.0) * (1.0 - flameIntensity) * 0.3;
        
        // Add digital flicker
        float flicker = sin(time * 20.0) * 0.1 + 0.9;
        alpha *= flicker;
        
        // Add scanlines
        float scanline = sin(screen_coords.y * 0.1) * 0.5 + 0.5;
        alpha *= scanline * 0.8 + 0.2;
        
        return vec4(fireColor, alpha);
    }
]]

-- Cyberpunk crystal burst effect
Shaders.crystalBurst = love.graphics.newShader[[
    extern float time;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(tex, texture_coords);
        float alpha = pixel.a * color.a;
        
        // Cyberpunk crystal color
        vec3 crystalColor = vec3(0.0, 1.0, 0.8); // Cyan
        
        // Add digital refraction
        float refraction = sin(screen_coords.x * 0.1 + time * 2.0) * 0.5 + 0.5;
        crystalColor += vec3(0.0, 0.8, 1.0) * refraction * 0.3;
        
        // Add digital sparkles
        float sparkle = sin(time * 10.0 + screen_coords.x * 0.5 + screen_coords.y * 0.5) * 0.5 + 0.5;
        crystalColor += vec3(1.0, 1.0, 1.0) * sparkle * 0.5;
        
        // Add neon glow
        float glow = sin(time * 3.0) * 0.5 + 0.5;
        alpha *= 1.0 + glow * 0.3;
        
        // Add scanlines
        float scanline = sin(screen_coords.y * 0.1) * 0.5 + 0.5;
        alpha *= scanline * 0.8 + 0.2;
        
        return vec4(crystalColor, alpha);
    }
]]

-- Cyberpunk storm blade effect
Shaders.stormBlade = love.graphics.newShader[[
    extern float time;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(tex, texture_coords);
        float alpha = pixel.a * color.a;
        
        // Cyberpunk storm color
        vec3 stormColor = vec3(0.0, 0.8, 1.0); // Electric blue
        
        // Add digital lightning
        float lightning = sin(time * 15.0 + screen_coords.x * 0.2) * 0.5 + 0.5;
        stormColor += vec3(0.0, 1.0, 1.0) * lightning * 0.7;
        
        // Add energy field
        float energy = sin(time * 3.0 + screen_coords.y * 0.1) * 0.5 + 0.5;
        alpha *= 1.0 + energy * 0.5;
        
        // Add digital arcs
        float arcs = sin(time * 20.0 + screen_coords.x * 0.5) * 0.5 + 0.5;
        stormColor += vec3(0.0, 1.0, 1.0) * arcs * 0.4;
        
        // Add scanlines
        float scanline = sin(screen_coords.y * 0.1) * 0.5 + 0.5;
        alpha *= scanline * 0.8 + 0.2;
        
        return vec4(stormColor, alpha);
    }
]]

-- Cyberpunk dash effect
Shaders.dash = love.graphics.newShader[[
    extern float time;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(tex, texture_coords);
        float alpha = pixel.a * color.a;
        
        // Digital motion blur
        float blur = sin(time * 10.0) * 0.5 + 0.5;
        alpha *= 1.0 - blur * 0.5;
        
        // Cyberpunk energy trail
        vec3 dashColor = vec3(0.0, 1.0, 1.0); // Cyan
        float energy = sin(time * 15.0 + screen_coords.x * 0.1) * 0.5 + 0.5;
        dashColor += vec3(0.0, 0.8, 1.0) * energy * 0.5;
        
        // Add scanlines
        float scanline = sin(screen_coords.y * 0.1) * 0.5 + 0.5;
        alpha *= scanline * 0.8 + 0.2;
        
        return vec4(dashColor, alpha);
    }
]]

-- Cyberpunk damage flash effect
Shaders.damageFlash = love.graphics.newShader[[
    extern float time;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(tex, texture_coords);
        float alpha = pixel.a * color.a;
        
        // Digital shockwave
        float distance = length(screen_coords - resolution * 0.5) / resolution.x;
        float shockwave = sin(distance * 10.0 - time * 5.0) * 0.5 + 0.5;
        
        // Cyberpunk flash colors
        vec3 flashColor = vec3(1.0, 0.0, 0.8); // Hot pink
        flashColor += vec3(0.0, 1.0, 1.0) * shockwave * 0.5; // Cyan
        
        // Add glitch effect
        float glitch = sin(time * 50.0) * 0.5 + 0.5;
        alpha *= 1.0 + glitch * 0.3;
        
        // Add scanlines
        float scanline = sin(screen_coords.y * 0.1) * 0.5 + 0.5;
        alpha *= scanline * 0.8 + 0.2;
        
        return vec4(flashColor, alpha);
    }
]]

-- Function to apply a shader effect
function Shaders.applyEffect(effect, drawFunction)
    if effect then
        effect:send("time", time)
        effect:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})
        love.graphics.setShader(effect)
    end
    drawFunction()
    if effect then
        love.graphics.setShader()
    end
end

-- Function to apply screen effect
function Shaders.applyScreenEffect(dt)
    -- Update shader uniforms
    effects.bloom:send("time", love.timer.getTime())
    effects.glow:send("time", love.timer.getTime())
    effects.ripple:send("time", love.timer.getTime())
    effects.ripple:send("mousePos", {love.mouse.getX(), love.mouse.getY()})
    
    -- Apply effects in sequence
    local shader = effects.bloom
    shader:send("dimensions", {love.graphics.getWidth(), love.graphics.getHeight()})
    
    -- Add subtle pulsing to bloom intensity
    local pulse = math.sin(love.timer.getTime() * 2) * 0.1 + 0.9
    shader:send("bloomIntensity", 0.5 * pulse)
    
    return shader
end

function Shaders.applyGlowEffect(x, y, radius, color)
    local shader = effects.glow
    shader:send("dimensions", {love.graphics.getWidth(), love.graphics.getHeight()})
    shader:send("glowColor", color)
    shader:send("intensity", radius)
    return shader
end

function Shaders.applyRippleEffect(x, y, strength)
    local shader = effects.ripple
    shader:send("dimensions", {love.graphics.getWidth(), love.graphics.getHeight()})
    shader:send("mousePos", {x, y})
    shader:send("rippleStrength", strength)
    return shader
end

return Shaders 
local PostProcess = {
    shaders = {},
    currentCanvas = nil,
    previousCanvas = nil
}

-- Initialize post-processing effects
function PostProcess.initialize()
    -- Create shaders
    PostProcess.shaders.bloom = love.graphics.newShader([[
        uniform float bloomIntensity;
        uniform float vignetteIntensity;
        
        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
            // Sample the texture
            vec4 pixel = Texel(tex, tc);
            
            // Apply bloom
            vec4 bloom = vec4(0.0);
            for(float i = -4.0; i <= 4.0; i += 1.0) {
                for(float j = -4.0; j <= 4.0; j += 1.0) {
                    vec2 offset = vec2(i, j) * 0.004;
                    bloom += Texel(tex, tc + offset);
                }
            }
            bloom /= 81.0;
            pixel += bloom * bloomIntensity;
            
            // Apply vignette
            vec2 center = vec2(0.5, 0.5);
            float dist = distance(tc, center);
            float vignette = 1.0 - dist * vignetteIntensity;
            pixel.rgb *= vignette;
            
            return pixel;
        }
    ]])
    
    -- Create render targets
    PostProcess.currentCanvas = love.graphics.newCanvas()
    PostProcess.previousCanvas = love.graphics.newCanvas()
    
    -- Initialize shader uniforms
    PostProcess.shaders.bloom:send("bloomIntensity", 0.7)
    PostProcess.shaders.bloom:send("vignetteIntensity", 0.4)
end

-- Begin post-processing
function PostProcess.begin()
    -- Store the current canvas
    PostProcess.previousCanvas = PostProcess.currentCanvas
    
    -- Create a new canvas for this frame
    PostProcess.currentCanvas = love.graphics.newCanvas()
    
    -- Set the new canvas as the render target
    love.graphics.setCanvas(PostProcess.currentCanvas)
    love.graphics.clear()
end

-- Finish post-processing and apply effects
function PostProcess.finish()
    -- Reset to default canvas
    love.graphics.setCanvas()
    
    -- Apply post-processing effects
    love.graphics.setShader(PostProcess.shaders.bloom)
    
    -- Draw the processed frame
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(PostProcess.currentCanvas)
    
    -- Reset shader
    love.graphics.setShader()
    
    -- Clean up old canvas
    if PostProcess.previousCanvas then
        PostProcess.previousCanvas:release()
    end
end

-- Apply post-processing to a specific canvas
function PostProcess.apply(canvas, settings)
    -- Reset to default canvas
    love.graphics.setCanvas()
    
    -- Apply post-processing effects
    love.graphics.setShader(PostProcess.shaders.bloom)
    
    -- Update shader uniforms if settings are provided
    if settings then
        if settings.bloomIntensity then
            PostProcess.shaders.bloom:send("bloomIntensity", settings.bloomIntensity)
        end
        if settings.vignetteIntensity then
            PostProcess.shaders.bloom:send("vignetteIntensity", settings.vignetteIntensity)
        end
    end
    
    -- Draw the processed frame
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas)
    
    -- Reset shader
    love.graphics.setShader()
end

return PostProcess 
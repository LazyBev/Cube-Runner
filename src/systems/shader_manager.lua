local ShaderManager = {
    shaders = {},
    canvas = nil
}

local mousePos = {x = 0, y = 0}
local time = 0

function ShaderManager.init()
    -- Load shaders
    ShaderManager.shaders.glow = love.graphics.newShader("shaders/glow.glsl")
    ShaderManager.shaders.ripple = love.graphics.newShader("shaders/ripple.glsl")
    ShaderManager.shaders.bloom = love.graphics.newShader("shaders/bloom.glsl")
    
    -- Create canvas for post-processing
    ShaderManager.canvas = love.graphics.newCanvas()
    
    -- Initialize shader uniforms
    local w, h = love.graphics.getDimensions()
    
    -- Glow shader uniforms
    ShaderManager.shaders.glow:send("time", 0)
    ShaderManager.shaders.glow:send("glowColor", {1, 1, 1})
    ShaderManager.shaders.glow:send("intensity", 0.5)
    
    -- Ripple shader uniforms
    ShaderManager.shaders.ripple:send("time", 0)
    ShaderManager.shaders.ripple:send("mousePos", {0, 0})
    ShaderManager.shaders.ripple:send("rippleStrength", 0.1)
    
    -- Bloom shader uniforms
    ShaderManager.shaders.bloom:send("time", 0)
    ShaderManager.shaders.bloom:send("bloomIntensity", 0.5)
    ShaderManager.shaders.bloom:send("bloomThreshold", 0.7)
end

function ShaderManager.update(dt)
    time = time + dt
    
    -- Update shader time
    ShaderManager.shaders.glow:send("time", time)
    ShaderManager.shaders.ripple:send("time", time)
    ShaderManager.shaders.bloom:send("time", time)
    
    -- Update mouse position
    ShaderManager.shaders.ripple:send("mousePos", {mousePos.x, mousePos.y})
end

function ShaderManager.setMousePosition(x, y)
    mousePos.x = x
    mousePos.y = y
end

function ShaderManager.setGlowColor(r, g, b)
    ShaderManager.shaders.glow:send("glowColor", {r, g, b})
end

function ShaderManager.setGlowIntensity(intensity)
    ShaderManager.shaders.glow:send("intensity", intensity)
end

function ShaderManager.setRippleStrength(strength)
    ShaderManager.shaders.ripple:send("rippleStrength", strength)
end

function ShaderManager.setBloomIntensity(intensity)
    ShaderManager.shaders.bloom:send("bloomIntensity", intensity)
end

function ShaderManager.setBloomThreshold(threshold)
    ShaderManager.shaders.bloom:send("bloomThreshold", threshold)
end

function ShaderManager.applyGlow(drawFunc)
    love.graphics.setCanvas(ShaderManager.canvas)
    love.graphics.clear()
    drawFunc()
    love.graphics.setCanvas()
    
    love.graphics.setShader(ShaderManager.shaders.glow)
    love.graphics.draw(ShaderManager.canvas)
    love.graphics.setShader()
end

function ShaderManager.applyRipple(drawFunc)
    love.graphics.setCanvas(ShaderManager.canvas)
    love.graphics.clear()
    drawFunc()
    love.graphics.setCanvas()
    
    love.graphics.setShader(ShaderManager.shaders.ripple)
    love.graphics.draw(ShaderManager.canvas)
    love.graphics.setShader()
end

function ShaderManager.applyBloom(drawFunc)
    love.graphics.setCanvas(ShaderManager.canvas)
    love.graphics.clear()
    drawFunc()
    love.graphics.setCanvas()
    
    love.graphics.setShader(ShaderManager.shaders.bloom)
    love.graphics.draw(ShaderManager.canvas)
    love.graphics.setShader()
end

return ShaderManager 
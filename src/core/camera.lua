local Camera = {
    x = 0,
    y = 0,
    targetX = 0,
    targetY = 0,
    shake = {
        intensity = 0,
        duration = 0,
        elapsed = 0
    },
    zoom = 1,
    targetZoom = 1,
    smoothness = 0.1,  -- Lower = smoother
    zoomSmoothness = 0.05,
    minZoom = 0.5,
    maxZoom = 2.0
}

function Camera.initialize()
    Camera.x = 0
    Camera.y = 0
    Camera.targetX = 0
    Camera.targetY = 0
    Camera.shake = {
        intensity = 0,
        duration = 0,
        elapsed = 0
    }
    Camera.zoom = 1
    Camera.targetZoom = 1
end

function Camera.update(dt)
    -- Update shake
    if Camera.shake.duration > 0 then
        Camera.shake.elapsed = Camera.shake.elapsed + dt
        if Camera.shake.elapsed >= Camera.shake.duration then
            Camera.shake.intensity = 0
            Camera.shake.duration = 0
            Camera.shake.elapsed = 0
        end
    end
    
    -- Smooth camera movement
    local dx = Camera.targetX - Camera.x
    local dy = Camera.targetY - Camera.y
    Camera.x = Camera.x + dx * Camera.smoothness
    Camera.y = Camera.y + dy * Camera.smoothness
    
    -- Smooth zoom
    local dz = Camera.targetZoom - Camera.zoom
    Camera.zoom = Camera.zoom + dz * Camera.zoomSmoothness
    
    -- Clamp zoom
    Camera.zoom = math.max(Camera.minZoom, math.min(Camera.maxZoom, Camera.zoom))
end

function Camera.setTarget(x, y)
    Camera.targetX = x
    Camera.targetY = y
end

function Camera.setZoom(zoom)
    Camera.targetZoom = math.max(Camera.minZoom, math.min(Camera.maxZoom, zoom))
end

function Camera.startShake(intensity, duration)
    Camera.shake.intensity = intensity
    Camera.shake.duration = duration
    Camera.shake.elapsed = 0
end

function Camera.push()
    love.graphics.push()
    
    -- Apply shake
    local shakeX = 0
    local shakeY = 0
    if Camera.shake.intensity > 0 then
        local progress = Camera.shake.elapsed / Camera.shake.duration
        local currentIntensity = Camera.shake.intensity * (1 - progress)
        shakeX = (math.random() * 2 - 1) * currentIntensity
        shakeY = (math.random() * 2 - 1) * currentIntensity
    end
    
    -- Apply camera transform
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    love.graphics.scale(Camera.zoom)
    love.graphics.translate(-Camera.x + shakeX, -Camera.y + shakeY)
end

function Camera.pop()
    love.graphics.pop()
end

function Camera.getWorldPosition(screenX, screenY)
    local worldX = (screenX - love.graphics.getWidth()/2) / Camera.zoom + Camera.x
    local worldY = (screenY - love.graphics.getHeight()/2) / Camera.zoom + Camera.y
    return worldX, worldY
end

function Camera.getScreenPosition(worldX, worldY)
    local screenX = (worldX - Camera.x) * Camera.zoom + love.graphics.getWidth()/2
    local screenY = (worldY - Camera.y) * Camera.zoom + love.graphics.getHeight()/2
    return screenX, screenY
end

return Camera 
local Constants = require("utils.constants")

local Animations = {}

function Animations.createWinParticles(x, y, color, winAnimation)
    -- Create victory beams with enhanced effects
    for i = 1, 12 do  -- Increased from 8 to 12 for more dramatic effect
        local angle = (i - 1) * math.pi / 6
        table.insert(winAnimation.victoryBeams, {
            x = x,
            y = y,
            angle = angle,
            length = 0,
            maxLength = love.graphics.getWidth() * 0.9,  -- Increased from 0.8 to 0.9
            width = love.graphics.getHeight() * 0.03,    -- Increased from 0.02 to 0.03
            life = 2.5,  -- Increased from 2 to 2.5
            maxLife = 2.5,
            color = color,
            glow = 0.8,  -- Added glow property
            pulse = 0    -- Added pulse property
        })
    end
    
    -- Create particles with enhanced effects
    for i = 1, 80 do  -- Increased from 50 to 80
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(150, 400)  -- Increased speed range
        table.insert(winAnimation.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = love.math.random(6, 12) * math.min(love.graphics.getWidth() / 1280, love.graphics.getHeight() / 720),
            life = 2.5,  -- Increased from 2 to 2.5
            maxLife = 2.5,
            color = color,
            rotation = love.math.random() * math.pi * 2,
            rotationSpeed = (love.math.random() - 0.5) * 8,  -- Increased rotation speed
            type = love.math.random() < 0.5 and "circle" or "square",
            glow = 0.8,  -- Added glow property
            trail = {}   -- Added trail property
        })
    end
    
    -- Create sparkles with enhanced effects
    for i = 1, 40 do  -- Increased from 20 to 40
        table.insert(winAnimation.sparkles, {
            x = love.math.random(0, love.graphics.getWidth()),
            y = love.math.random(0, love.graphics.getHeight()),
            size = love.math.random(3, 6) * math.min(love.graphics.getWidth() / 1280, love.graphics.getHeight() / 720),
            life = love.math.random(0.8, 1.5),  -- Increased life range
            maxLife = 1.5,
            color = color,
            glow = 0.8,  -- Added glow property
            pulse = 0    -- Added pulse property
        })
    end
end

function Animations.updateWinAnimation(winAnimation, dt)
    if not winAnimation.active then return end
    
    winAnimation.elapsed = winAnimation.elapsed + dt
    local progress = math.sin(winAnimation.elapsed * 0.5) * 0.5 + 0.5
    
    -- Enhanced scale and rotation animations
    winAnimation.scale = 1 + math.sin(winAnimation.elapsed * 2) * 0.15  -- Increased scale range
    winAnimation.rotation = winAnimation.elapsed * 0.8  -- Increased rotation speed
    
    -- Enhanced text effects
    winAnimation.textAlpha = 1
    winAnimation.textGlow = math.sin(winAnimation.elapsed * 2) * 0.5 + 0.5
    
    -- Enhanced camera movement
    winAnimation.cameraOffset.x = math.sin(winAnimation.elapsed * 2) * 8  -- Increased movement range
    winAnimation.cameraOffset.y = math.cos(winAnimation.elapsed * 2) * 8
    
    -- Update particles with enhanced effects
    for i = #winAnimation.particles, 1, -1 do
        local p = winAnimation.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = p.vx * 0.98
        p.vy = p.vy * 0.98
        p.life = p.life - dt
        if p.rotationSpeed then
            p.rotation = p.rotation + p.rotationSpeed * dt
        end
        
        -- Update particle trail
        table.insert(p.trail, 1, {x = p.x, y = p.y, alpha = 1})
        if #p.trail > 10 then  -- Limit trail length
            table.remove(p.trail)
        end
        for j, point in ipairs(p.trail) do
            point.alpha = point.alpha - dt * 2
        end
        
        if p.life <= 0 then
            -- Enhanced particle reset
            p.x = love.graphics.getWidth()/2
            p.y = love.graphics.getHeight()/2
            local angle = love.math.random() * math.pi * 2
            local speed = love.math.random(150, 400)
            p.vx = math.cos(angle) * speed
            p.vy = math.sin(angle) * speed
            p.life = p.maxLife
            p.trail = {}  -- Reset trail
        end
    end
    
    -- Update victory beams with enhanced effects
    for i = #winAnimation.victoryBeams, 1, -1 do
        local beam = winAnimation.victoryBeams[i]
        beam.length = math.min(beam.maxLength, beam.length + 250 * dt)  -- Increased speed
        beam.life = beam.life - dt
        beam.pulse = beam.pulse + dt * 2
        beam.glow = 0.8 + math.sin(beam.pulse) * 0.2  -- Pulsing glow effect
        
        if beam.life <= 0 then
            beam.length = 0
            beam.life = beam.maxLife
            beam.pulse = 0
        end
    end
    
    -- Update sparkles with enhanced effects
    for i = #winAnimation.sparkles, 1, -1 do
        local sparkle = winAnimation.sparkles[i]
        sparkle.life = sparkle.life - dt
        sparkle.size = sparkle.size * 0.98
        sparkle.pulse = sparkle.pulse + dt * 3
        sparkle.glow = 0.8 + math.sin(sparkle.pulse) * 0.2  -- Pulsing glow effect
        
        if sparkle.life <= 0 then
            sparkle.x = love.math.random(0, love.graphics.getWidth())
            sparkle.y = love.math.random(0, love.graphics.getHeight())
            sparkle.size = love.math.random(3, 6)
            sparkle.life = sparkle.maxLife
            sparkle.pulse = 0
        end
    end
end

function Animations.drawWinAnimation(winAnimation, winner)
    if not winAnimation.active then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local scale = math.min(w / 1280, h / 720)
    
    -- Enhanced shader background
    if winAnimation.shader then
        winAnimation.shader:send("time", winAnimation.elapsed)
        winAnimation.shader:send("resolution", {w, h})
        winAnimation.shader:send("winnerColor", {winAnimation.particles[1].color[1], 
                                               winAnimation.particles[1].color[2], 
                                               winAnimation.particles[1].color[3]})
        winAnimation.shader:send("intensity", math.sin(winAnimation.elapsed) * 0.5 + 0.5)
        
        love.graphics.setShader(winAnimation.shader)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setShader()
    end
    
    -- Draw victory beams with enhanced effects
    for _, beam in ipairs(winAnimation.victoryBeams) do
        local alpha = beam.life / beam.maxLife
        love.graphics.setColor(beam.color[1], beam.color[2], beam.color[3], alpha * beam.glow)
        love.graphics.push()
        love.graphics.translate(beam.x, beam.y)
        love.graphics.rotate(beam.angle)
        love.graphics.rectangle("fill", 0, -beam.width/2, beam.length, beam.width)
        love.graphics.pop()
    end
    
    -- Draw particles with enhanced effects
    for _, p in ipairs(winAnimation.particles) do
        local alpha = p.life / p.maxLife
        
        -- Draw particle trail
        for i, point in ipairs(p.trail) do
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], point.alpha * 0.3)
            love.graphics.circle("fill", point.x, point.y, p.size/2 * (i/#p.trail))
        end
        
        -- Draw main particle
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * p.glow)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        if p.rotation then
            love.graphics.rotate(p.rotation)
        end
        if p.type == "circle" then
            love.graphics.circle("fill", 0, 0, p.size/2)
        else
            love.graphics.rectangle("fill", -p.size/2, -p.size/2, p.size, p.size)
        end
        love.graphics.pop()
    end
    
    -- Draw sparkles with enhanced effects
    for _, sparkle in ipairs(winAnimation.sparkles) do
        local alpha = sparkle.life / sparkle.maxLife
        love.graphics.setColor(sparkle.color[1], sparkle.color[2], sparkle.color[3], alpha * sparkle.glow)
        love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
    end
    
    -- Draw winner text with enhanced effects
    local titleFont = love.graphics.newFont(math.min(64 * scale, h * 0.09))  -- Increased size
    love.graphics.setFont(titleFont)
    local text = winner
    local textWidth = titleFont:getWidth(text)
    local textHeight = titleFont:getHeight()
    
    -- Enhanced text glow
    love.graphics.setColor(1, 1, 1, winAnimation.textGlow * 0.8)
    love.graphics.push()
    love.graphics.translate(w/2 + winAnimation.cameraOffset.x, 
                          h/2 + winAnimation.cameraOffset.y)
    love.graphics.scale(winAnimation.scale * 1.2)  -- Increased glow scale
    love.graphics.rotate(winAnimation.rotation * 0.1)
    love.graphics.print(text, -textWidth/2, -textHeight/2)
    love.graphics.pop()
    
    -- Main text with enhanced effects
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.push()
    love.graphics.translate(w/2 + winAnimation.cameraOffset.x, 
                          h/2 + winAnimation.cameraOffset.y)
    love.graphics.scale(winAnimation.scale)
    love.graphics.rotate(winAnimation.rotation * 0.1)
    love.graphics.print(text, -textWidth/2, -textHeight/2)
    love.graphics.pop()
    
    -- Enhanced continue prompt
    local promptFont = love.graphics.newFont(math.min(32 * scale, h * 0.045))  -- Increased size
    love.graphics.setFont(promptFont)
    local promptText = "Press SPACE or ENTER to continue"
    local promptWidth = promptFont:getWidth(promptText)
    local promptHeight = promptFont:getHeight()
    
    -- Enhanced prompt animation
    local promptAlpha = 0.7 + math.sin(love.timer.getTime() * 3) * 0.3
    love.graphics.setColor(1, 1, 1, promptAlpha)
    love.graphics.printf(promptText, 0, h - h * 0.15, w, "center")
end

return Animations 
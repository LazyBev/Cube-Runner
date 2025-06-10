local Obstacles = {
    spawnTimer = 0,
    spawnInterval = 1.0,
    maxObstacles = 20
}

function Obstacles.update(dt)
    -- Update spawn timer
    Obstacles.spawnTimer = Obstacles.spawnTimer + dt
    if Obstacles.spawnTimer >= Obstacles.spawnInterval then
        Obstacles.spawnTimer = 0
        -- Spawn new obstacle if under max
        if #Obstacles.obstacles < Obstacles.maxObstacles then
            Obstacles.spawnObstacle()
        end
    end

    -- Update obstacles
    for i = #Obstacles.obstacles, 1, -1 do
        local obs = Obstacles.obstacles[i]
        obs.y = obs.y + obs.speed * dt
        obs.rotation = obs.rotation + obs.rotationSpeed * dt
        
        -- Remove if off screen
        if obs.y > love.graphics.getHeight() + obs.height then
            table.remove(Obstacles.obstacles, i)
        end
    end
end

function Obstacles.draw()
    for _, obs in ipairs(Obstacles.obstacles) do
        -- Draw shadow
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", obs.x + 5, obs.y + 5, obs.width, obs.height)
        
        -- Draw glow
        love.graphics.setColor(obs.color[1], obs.color[2], obs.color[3], 0.2)
        love.graphics.rectangle("fill", obs.x - 5, obs.y - 5, obs.width + 10, obs.height + 10)
        
        -- Draw main obstacle
        love.graphics.setColor(obs.color)
        love.graphics.push()
        love.graphics.translate(obs.x + obs.width/2, obs.y + obs.height/2)
        love.graphics.rotate(obs.rotation)
        love.graphics.rectangle("fill", -obs.width/2, -obs.height/2, obs.width, obs.height)
        love.graphics.pop()
        
        -- Draw warning indicator if near top of screen
        if obs.y < 100 then
            local alpha = math.sin(love.timer.getTime() * 10) * 0.3 + 0.7
            love.graphics.setColor(1, 0, 0, alpha)
            love.graphics.rectangle("fill", obs.x, 0, obs.width, 5)
        end
    end
end

function Obstacles.spawnObstacle()
    local width = love.math.random(30, 60)
    local height = love.math.random(30, 60)
    local x = love.math.random(0, love.graphics.getWidth() - width)
    local y = -height
    
    -- Random color based on damage
    local damage = love.math.random(1, 3)
    local color = {
        r = math.min(1, 0.3 + damage * 0.2),
        g = math.max(0, 0.3 - damage * 0.1),
        b = math.max(0, 0.3 - damage * 0.1)
    }
    
    table.insert(Obstacles.obstacles, {
        x = x,
        y = y,
        width = width,
        height = height,
        speed = love.math.random(100, 200),
        damage = damage,
        color = color,
        rotation = 0,
        rotationSpeed = love.math.random(-2, 2)
    })
end

function Obstacles.init()
    Obstacles.obstacles = {}
end

return Obstacles 
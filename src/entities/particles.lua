local Constants = require("utils.constants")

local Particles = {
    particles = {}
}

function Particles.update(dt)
    for i = #Particles.particles, 1, -1 do
        local p = Particles.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = p.vx * 0.95
        p.vy = p.vy * 0.95
        p.life = p.life - dt

        if p.life <= 0 then
            table.remove(Particles.particles, i)
        end
    end
end

function Particles.draw()
    for _, p in ipairs(Particles.particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
end

function Particles.addDashParticles(player)
    for i = 1, 2 do
        table.insert(Particles.particles, {
            x = player.x + love.math.random(-10, 10),
            y = player.y + love.math.random(-10, 10),
            vx = love.math.random(-50, 50),
            vy = love.math.random(-50, 50),
            life = 0.5,
            maxLife = 0.5,
            size = love.math.random(2, 4),
            color = player.color
        })
    end
end

function Particles.addHitParticles(x, y, color)
    for i = 1, 8 do
        table.insert(Particles.particles, {
            x = x + love.math.random(-15, 15),
            y = y + love.math.random(-15, 15),
            vx = love.math.random(-100, 100),
            vy = love.math.random(-100, 100),
            life = 0.8,
            maxLife = 0.8,
            size = love.math.random(3, 6),
            color = color
        })
    end
end

function Particles.createComboParticles(x, y, combo)
    for i = 1, 10 do
        table.insert(Particles.particles, {
            x = x + love.math.random(-20, 20),
            y = y + love.math.random(-20, 20),
            vx = love.math.random(-100, 100),
            vy = love.math.random(-100, 100),
            life = 1.0,
            maxLife = 1.0,
            size = love.math.random(4, 8),
            color = {1, 1, 0}  -- Yellow for combo particles
        })
    end
end

function Particles.clear()
    Particles.particles = {}
end

return Particles 
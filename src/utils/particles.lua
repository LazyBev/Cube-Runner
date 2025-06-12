local ParticleSystem = {}

function ParticleSystem:new()
    local o = {
        particles = {}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function ParticleSystem:create(x, y, type)
    local particle = {
        x = x,
        y = y,
        type = type,
        life = 1,
        size = 10,
        color = {1, 1, 1, 1}
    }
    table.insert(self.particles, particle)
end

function ParticleSystem:update(dt)
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt
        if particle.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function ParticleSystem:draw()
    for _, particle in ipairs(self.particles) do
        love.graphics.setColor(particle.color)
        love.graphics.circle('fill', particle.x, particle.y, particle.size)
    end
end

return ParticleSystem 
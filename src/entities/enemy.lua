local Enemy = {
    size = 15,
    speed = 100,
    health = 1,
    color = {1, 0.2, 0.2}
}

function Enemy:new(x, y, wave)
    local o = {
        x = x,
        y = y,
        size = self.size,
        speed = self.speed + wave * 10,
        health = self.health,
        color = self.color
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Enemy:update(dt, player)
    -- Move towards player
    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist > 0 then
        self.x = self.x + (dx / dist) * self.speed * dt
        self.y = self.y + (dy / dist) * self.speed * dt
    end
end

function Enemy:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.size)
end

return Enemy 
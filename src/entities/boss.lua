local Boss = {
    size = 40,
    speed = 80,
    health = 5,
    color = {1, 0.5, 0}
}

function Boss:new(x, y, wave)
    local o = {
        x = x,
        y = y,
        size = self.size,
        speed = self.speed + wave * 5,
        health = self.health + wave,
        color = self.color
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Boss:update(dt, player)
    -- Move towards player
    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist > 0 then
        self.x = self.x + (dx / dist) * self.speed * dt
        self.y = self.y + (dy / dist) * self.speed * dt
    end
end

function Boss:draw()
    love.graphics.setColor(self.color)
    love.graphics.polygon("fill",
        self.x, self.y - self.size,
        self.x + self.size, self.y + self.size,
        self.x - self.size, self.y + self.size
    )
end

function Boss:takeDamage()
    self.health = self.health - 1
    return self.health <= 0
end

return Boss 
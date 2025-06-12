local Player = {
    x = 400,
    y = 300,
    size = 30,
    speed = 200,
    dashSpeed = 400,
    dashDuration = 0.2,
    dashCooldown = 1,
    isDashing = false,
    dashTimer = 0,
    dashCooldownTimer = 0,
    trail = {},
    trailLength = 10,
    trailFadeTime = 0.5,
    prevX = 0,
    prevY = 0,
    dashDirection = { x = 0, y = 0 },
    health = 10,
    maxHealth = 10,
    level = 1,
    dashDamage = 1
}

function Player:new(x, y)
    local o = {
        x = x or self.x,
        y = y or self.y,
        size = self.size,
        speed = self.speed,
        dashSpeed = self.dashSpeed,
        dashDuration = self.dashDuration,
        dashCooldown = self.dashCooldown,
        isDashing = self.isDashing,
        dashTimer = self.dashTimer,
        dashCooldownTimer = self.dashCooldownTimer,
        trail = {},
        trailLength = self.trailLength,
        trailFadeTime = self.trailFadeTime,
        prevX = self.prevX,
        prevY = self.prevY,
        dashDirection = self.dashDirection,
        health = self.health,
        maxHealth = self.maxHealth,
        level = self.level,
        dashDamage = self.dashDamage
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Player:update(dt, controls)
    -- Store previous position for trail
    self.prevX = self.x
    self.prevY = self.y
    
    -- Handle dash cooldown
    if self.dashCooldownTimer > 0 then
        self.dashCooldownTimer = self.dashCooldownTimer - dt
    end
    
    -- Handle dash
    if self.isDashing then
        self.dashTimer = self.dashTimer - dt
        if self.dashTimer <= 0 then
            self.isDashing = false
            self.dashCooldownTimer = self.dashCooldown
        else
            -- Move in dash direction
            self.x = self.x + self.dashDirection.x * self.dashSpeed * dt
            self.y = self.y + self.dashDirection.y * self.dashSpeed * dt
        end
    else
        -- Regular movement
        local dx, dy = 0, 0
        if love.keyboard.isDown(controls.left) then dx = dx - 1 end
        if love.keyboard.isDown(controls.right) then dx = dx + 1 end
        if love.keyboard.isDown(controls.up) then dy = dy - 1 end
        if love.keyboard.isDown(controls.down) then dy = dy + 1 end
        
        -- Normalize diagonal movement
        if dx ~= 0 and dy ~= 0 then
            dx = dx * 0.7071 -- 1/sqrt(2)
            dy = dy * 0.7071
        end
        
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
        
        -- Store dash direction
        if dx ~= 0 or dy ~= 0 then
            self.dashDirection.x = dx
            self.dashDirection.y = dy
        end
    end
    
    -- Keep player within screen bounds
    self.x = math.max(self.size, math.min(love.graphics.getWidth() - self.size, self.x))
    self.y = math.max(self.size, math.min(love.graphics.getHeight() - self.size, self.y))
    
    -- Update trail
    if self.isDashing then
        table.insert(self.trail, 1, {
            x = self.x,
            y = self.y,
            size = self.size,
            alpha = 1
        })
        
        if #self.trail > self.trailLength then
            table.remove(self.trail)
        end
    end
    
    -- Update trail fade
    for i = #self.trail, 1, -1 do
        self.trail[i].alpha = self.trail[i].alpha - dt / self.trailFadeTime
        if self.trail[i].alpha <= 0 then
            table.remove(self.trail, i)
        end
    end
end

function Player:draw()
    -- Draw trail
    for _, segment in ipairs(self.trail) do
        love.graphics.setColor(0, 1, 1, segment.alpha * 0.8) -- Cyan color with fading alpha
        love.graphics.rectangle('fill', segment.x - segment.size/2, segment.y - segment.size/2, segment.size, segment.size)
    end
    
    -- Draw player
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('fill', self.x - self.size/2, self.y - self.size/2, self.size, self.size)
end

function Player:startDash()
    if not self.isDashing and self.dashCooldownTimer <= 0 then
        self.isDashing = true
        self.dashTimer = self.dashDuration
        self.trail = {} -- Clear trail on new dash
    end
end

function Player:getTrail()
    return self.trail
end

return Player 
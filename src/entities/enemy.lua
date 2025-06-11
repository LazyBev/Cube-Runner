local Enemy = {}
Enemy.__index = Enemy

-- Load required modules
local MenuSystem = require("systems.menu_system")

local gameState = nil

function Enemy.init(state)
    gameState = state
end

function Enemy.new(type, x, y)
    local self = setmetatable({}, Enemy)
    
    self.type = type
    self.x = x
    self.y = y
    self.speed = 100
    self.size = 20
    self.health = 100
    self.damage = 10
    self.scoreValue = 100
    self.coinValue = 10
    
    -- Get colors from settings
    local settings = MenuSystem.getSettings()
    
    if type == "small" then
        self.speed = 150
        self.size = 15
        self.health = 50
        self.damage = 5
        self.scoreValue = 50
        self.coinValue = 5
        self.color = settings.colors.smallEnemy
    else -- large
        self.speed = 80
        self.size = 30
        self.health = 200
        self.damage = 20
        self.scoreValue = 200
        self.coinValue = 20
        self.color = settings.colors.largeEnemy
    end
    
    return self
end

function Enemy:update(dt)
    -- Move towards player
    if gameState.player then
        local dx = gameState.player.x - self.x
        local dy = gameState.player.y - self.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > 0 then
            self.x = self.x + (dx / distance) * self.speed * dt
            self.y = self.y + (dy / distance) * self.speed * dt
        end
    end
end

function Enemy:draw()
    -- Draw enemy
    love.graphics.setColor(self.color)
    if self.type == "small" then
        love.graphics.circle("fill", self.x, self.y, self.size)
    else
        -- Draw triangle for large enemies
        local size = self.size
        love.graphics.polygon("fill",
            self.x, self.y - size,
            self.x - size, self.y + size,
            self.x + size, self.y + size
        )
    end
    
    -- Draw health bar
    local healthBarWidth = self.size * 2
    local healthBarHeight = 5
    local healthPercentage = self.health / (self.type == "small" and 50 or 200)
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x - healthBarWidth/2, self.y - self.size - 10, healthBarWidth, healthBarHeight)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", self.x - healthBarWidth/2, self.y - self.size - 10, healthBarWidth * healthPercentage, healthBarHeight)
end

function Enemy:takeDamage(amount)
    self.health = self.health - amount
    return self.health <= 0
end

return Enemy 
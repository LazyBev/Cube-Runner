local Player = {}
Player.__index = Player

-- Load audio manager
local AudioManager = require("systems.audio_manager")
local MenuSystem = require("systems.menu_system")
local ClassSystem = require("systems.class_system")
local Shaders = require("shaders")

-- Class definitions
local classes = {
    VOID_KNIGHT = {
        name = "Void Knight",
        health = 180,
        damage = 25,
        dashDamage = 80,
        speed = 220,
        dashSpeed = 800,
        dashCooldown = 1.2,
        color = {0.4, 0.1, 0.5},
        dashColor = {0.6, 0.2, 0.8},
        voidTrail = {
            duration = 0.5,
            damage = 20,
            interval = 0.1
        }
    },
    STORM_BLADE = {
        name = "Storm Blade",
        health = 90,
        damage = 15,
        dashDamage = 40,
        speed = 400,
        dashSpeed = 1000,
        dashCooldown = 0.8,
        color = {0.2, 0.7, 0.9},
        dashColor = {0.4, 0.9, 1.0},
        chainBonus = {
            maxStacks = 3,
            damageMultiplier = 1.5
        }
    },
    CRYSTAL_SAGE = {
        name = "Crystal Sage",
        health = 120,
        damage = 30,
        dashDamage = 60,
        speed = 280,
        dashSpeed = 750,
        dashCooldown = 1.0,
        color = {0.8, 0.8, 0.2},
        dashColor = {1.0, 1.0, 0.4},
        crystalBurst = {
            radius = 100,
            damage = 30,
            shardCount = 8
        }
    },
    INFERNO_BERSERKER = {
        name = "Inferno Berserker",
        health = 150,
        damage = 35,
        dashDamage = 70,
        speed = 250,
        dashSpeed = 850,
        dashCooldown = 1.1,
        color = {0.8, 0.3, 0.1},
        dashColor = {1.0, 0.5, 0.2},
        fireTrail = {
            duration = 1.0,
            damage = 15,
            interval = 0.2
        }
    }
}

function Player.new(classType)
    local self = setmetatable({}, Player)
    
    -- Format class type to match the lookup format
    local formattedClassType = classType:upper():gsub(" ", "_")
    
    -- Get class data
    local classData = classes[formattedClassType]
    if not classData then
        error("Invalid class type: " .. classType)
    end
    
    -- Initialize player properties
    self.x = love.graphics.getWidth() / 2
    self.y = love.graphics.getHeight() / 2
    self.size = 30
    self.speed = classData.speed
    self.health = classData.health
    self.maxHealth = classData.health
    self.damage = classData.damage
    self.dashDamage = classData.dashDamage
    self.dashSpeed = classData.dashSpeed
    self.dashCooldown = classData.dashCooldown
    self.dashTimer = 0
    self.isDashing = false
    self.dashDirection = {x = 0, y = 0}
    self.classType = formattedClassType
    
    -- Get color from settings
    local settings = MenuSystem.getSettings()
    self.color = settings.colors.player
    
    -- Special ability properties
    self.specialActive = false
    self.specialTimer = 0
    self.specialCooldown = 5
    self.specialDuration = 3
    
    -- Initialize class-specific properties
    if formattedClassType == "VOID_KNIGHT" then
        self.voidTrail = {}
        self.voidTrailTimer = 0
        self.voidTrailInterval = 0.1
    elseif formattedClassType == "STORM_BLADE" then
        self.chainBonus = 1
        self.chainTimer = 0
        self.chainDuration = 2
    elseif formattedClassType == "CRYSTAL_SAGE" then
        self.crystalShards = {}
        self.crystalBurstTimer = 0
        self.crystalBurstCooldown = 8
    elseif formattedClassType == "INFERNO_BERSERKER" then
        self.fireTrail = {}
        self.fireTrailTimer = 0
        self.fireTrailInterval = 0.05
    end
    
    return self
end

function Player:update(dt)
    -- Update dash timer
    if self.dashTimer > 0 then
        self.dashTimer = self.dashTimer - dt
    end
    
    -- Update special ability timer
    if self.specialTimer > 0 then
        self.specialTimer = self.specialTimer - dt
        if self.specialTimer <= 0 then
            self.specialActive = false
        end
    end
    
    -- Handle movement
    if not self.isDashing then
        local moveX, moveY = 0, 0
        local settings = MenuSystem.getSettings()
        
        if love.keyboard.isDown(settings.keybinds.left) then moveX = moveX - 1 end
        if love.keyboard.isDown(settings.keybinds.right) then moveX = moveX + 1 end
        if love.keyboard.isDown(settings.keybinds.up) then moveY = moveY - 1 end
        if love.keyboard.isDown(settings.keybinds.down) then moveY = moveY + 1 end
        
        -- Normalize diagonal movement
        if moveX ~= 0 and moveY ~= 0 then
            moveX = moveX * 0.7071 -- 1/sqrt(2)
            moveY = moveY * 0.7071
        end
        
        self.x = self.x + moveX * self.speed * dt
        self.y = self.y + moveY * self.speed * dt
        
        -- Keep player in bounds
        self.x = math.max(self.size, math.min(love.graphics.getWidth() - self.size, self.x))
        self.y = math.max(self.size, math.min(love.graphics.getHeight() - self.size, self.y))
    else
        -- Update dash movement
        self.x = self.x + self.dashDirection.x * self.dashSpeed * dt
        self.y = self.y + self.dashDirection.y * self.dashSpeed * dt
        
        -- Check if dash should end
        if self.x < self.size or self.x > love.graphics.getWidth() - self.size or
           self.y < self.size or self.y > love.graphics.getHeight() - self.size then
            self.isDashing = false
        end
        
        -- Update class-specific dash effects
        if self.classType == "VOID_KNIGHT" then
            self:updateVoidTrail(dt)
        elseif self.classType == "STORM_BLADE" then
            self.chainTimer = self.chainDuration
        elseif self.classType == "INFERNO_BERSERKER" then
            self:updateFireTrail(dt)
        end
    end
    
    -- Update class-specific timers
    if self.classType == "STORM_BLADE" and self.chainTimer > 0 then
        self.chainTimer = self.chainTimer - dt
        if self.chainTimer <= 0 then
            self.chainBonus = 1
        end
    end
    
    if self.classType == "CRYSTAL_SAGE" then
        self.crystalBurstTimer = math.max(0, self.crystalBurstTimer - dt)
    end
end

function Player:draw()
    -- Draw player
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, self.size, self.size)
    
    -- Draw health bar
    local healthBarWidth = self.size * 2
    local healthBarHeight = 5
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x - healthBarWidth/2, self.y - self.size - 10, healthBarWidth, healthBarHeight)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", self.x - healthBarWidth/2, self.y - self.size - 10, healthBarWidth * (self.health / self.maxHealth), healthBarHeight)
    
    -- Draw dash cooldown indicator
    if self.dashTimer > 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", self.x - self.size/2, self.y + self.size/2 + 5, self.size * (1 - self.dashTimer / self.dashCooldown), 3)
    end
    
    -- Draw class-specific effects with shaders
    if self.classType == "VOID_KNIGHT" then
        for _, trail in ipairs(self.voidTrail) do
            Shaders.applyEffect(Shaders.voidTrail, function()
                love.graphics.rectangle("fill", trail.x - 10, trail.y - 10, 20, 20)
            end)
        end
    elseif self.classType == "STORM_BLADE" and self.chainTimer > 0 then
        Shaders.applyEffect(Shaders.stormBlade, function()
            love.graphics.circle("line", self.x, self.y, self.size * 1.5)
        end)
    elseif self.classType == "CRYSTAL_SAGE" then
        for _, shard in ipairs(self.crystalShards) do
            Shaders.applyEffect(Shaders.crystalBurst, function()
                love.graphics.polygon("fill", shard.x, shard.y - 10, shard.x - 5, shard.y + 5, shard.x + 5, shard.y + 5)
            end)
        end
    elseif self.classType == "INFERNO_BERSERKER" then
        for _, fire in ipairs(self.fireTrail) do
            Shaders.applyEffect(Shaders.fireTrail, function()
                love.graphics.circle("fill", fire.x, fire.y, 5)
            end)
        end
    end
    
    -- Draw dash effect if dashing
    if self.isDashing then
        Shaders.applyEffect(Shaders.dash, function()
            love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, self.size, self.size)
        end)
    end
end

function Player:dash()
    if self.dashTimer <= 0 then
        local moveX, moveY = 0, 0
        local settings = MenuSystem.getSettings()
        
        if love.keyboard.isDown(settings.keybinds.left) then moveX = moveX - 1 end
        if love.keyboard.isDown(settings.keybinds.right) then moveX = moveX + 1 end
        if love.keyboard.isDown(settings.keybinds.up) then moveY = moveY - 1 end
        if love.keyboard.isDown(settings.keybinds.down) then moveY = moveY + 1 end
        
        -- If no direction is pressed, dash in the last movement direction
        if moveX == 0 and moveY == 0 then
            moveX = 1 -- Default to right
        end
        
        -- Normalize dash direction
        local length = math.sqrt(moveX * moveX + moveY * moveY)
        self.dashDirection = {
            x = moveX / length,
            y = moveY / length
        }
        
        self.isDashing = true
        self.dashTimer = self.dashCooldown
        
        -- Activate class-specific dash effects
        if self.classType == "VOID_KNIGHT" then
            self:activateVoidTrail()
        elseif self.classType == "STORM_BLADE" then
            self.chainBonus = self.chainBonus + 0.5
        elseif self.classType == "CRYSTAL_SAGE" then
            self:activateCrystalBurst()
        elseif self.classType == "INFERNO_BERSERKER" then
            self:activateFireTrail()
        end
    end
end

function Player:takeDamage(amount)
    self.health = math.max(0, self.health - amount)
    AudioManager.playSound("hit")
    
    -- Apply damage flash effect
    Shaders.applyEffect(Shaders.damageFlash, function()
        love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, self.size, self.size)
    end)
    
    return self.health <= 0
end

function Player:applyUpgrade(upgrade)
    if upgrade.type == "health" then
        self.maxHealth = self.maxHealth + upgrade.value
        self.health = self.maxHealth
    elseif upgrade.type == "damage" then
        self.damage = self.damage + upgrade.value
    elseif upgrade.type == "speed" then
        self.speed = self.speed + upgrade.value
    elseif upgrade.type == "dash" then
        self.dashDamage = self.dashDamage + upgrade.value
        self.dashSpeed = self.dashSpeed + upgrade.value * 100
        self.dashCooldown = math.max(0.5, self.dashCooldown - upgrade.value * 0.5)
    end
end

-- Class-specific ability functions
function Player:activateVoidTrail()
    self.voidTrail = {}
    self.voidTrailTimer = 0
end

function Player:updateVoidTrail(dt)
    self.voidTrailTimer = self.voidTrailTimer + dt
    if self.voidTrailTimer >= self.voidTrailInterval then
        self.voidTrailTimer = 0
        table.insert(self.voidTrail, {x = self.x, y = self.y})
        if #self.voidTrail > 10 then
            table.remove(self.voidTrail, 1)
        end
    end
end

function Player:activateCrystalBurst()
    if self.crystalBurstTimer <= 0 then
        self.crystalShards = {}
        for i = 1, 8 do
            local angle = (i - 1) * math.pi / 4
            table.insert(self.crystalShards, {
                x = self.x + math.cos(angle) * 50,
                y = self.y + math.sin(angle) * 50,
                angle = angle
            })
        end
        self.crystalBurstTimer = self.crystalBurstCooldown
    end
end

function Player:activateFireTrail()
    self.fireTrail = {}
    self.fireTrailTimer = 0
end

function Player:updateFireTrail(dt)
    self.fireTrailTimer = self.fireTrailTimer + dt
    if self.fireTrailTimer >= self.fireTrailInterval then
        self.fireTrailTimer = 0
        table.insert(self.fireTrail, {x = self.x, y = self.y})
        if #self.fireTrail > 20 then
            table.remove(self.fireTrail, 1)
        end
    end
end

return Player 
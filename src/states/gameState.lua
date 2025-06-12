local Enemy = require('entities.enemy')
local Boss = require('entities.boss')
local Collision = require('utils.collision')

local GameState = {
    score = 0,
    wave = 1,
    spawnTimer = 0,
    spawnInterval = 1,
    gameTime = 0,
    enemies = {},
    bosses = {},
    maxEnemies = 50,
    enemySpawnRadius = 500,
    bossSpawnInterval = 30,
    bossWaveThreshold = 5 -- Bosses only spawn after this wave
}

function GameState:new(sounds)
    local o = {
        score = self.score,
        wave = self.wave,
        spawnTimer = self.spawnTimer,
        spawnInterval = self.spawnInterval,
        gameTime = self.gameTime,
        enemies = {},
        bosses = {},
        maxEnemies = self.maxEnemies,
        enemySpawnRadius = self.enemySpawnRadius,
        bossSpawnInterval = self.bossSpawnInterval,
        bossWaveThreshold = self.bossWaveThreshold,
        sounds = sounds
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function GameState:update(dt, player)
    self.gameTime = self.gameTime + dt
    self.spawnTimer = self.spawnTimer + dt
    
    -- Update enemies
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        enemy:update(dt, player)
        
        -- Check collision with player
        if not player.isDashing and Collision.checkCollision(enemy, player) then
            -- Game over logic here
            -- For now, just remove enemy on collision for demonstration
            table.remove(self.enemies, i)
        elseif player.isDashing and Collision.checkCollision(enemy, player) then
            -- Apply dash damage
            enemy.health = enemy.health - player.dashDamage
            if enemy.health <= 0 then
                table.remove(self.enemies, i)
                self.score = self.score + 10 -- Example score for dashing kill
            end
        end
    end
    
    -- Update bosses
    for i = #self.bosses, 1, -1 do
        local boss = self.bosses[i]
        boss:update(dt, player)
        
        -- Check collision with player
        if not player.isDashing and Collision.checkCollision(boss, player) then
            -- Game over logic here
            -- For now, just remove boss on collision for demonstration
            table.remove(self.bosses, i)
        elseif player.isDashing and Collision.checkCollision(boss, player) then
            -- Apply dash damage
            boss.health = boss.health - player.dashDamage
            if boss.health <= 0 then
                table.remove(self.bosses, i)
                self.score = self.score + 100 -- Example score for dashing boss kill
            end
        end
    end
end

function GameState:draw()
    -- Draw UI with cyberpunk style
    -- love.graphics.setColor(0, 1, 1) -- Cyan color for cyberpunk feel
    -- love.graphics.printf("Score: " .. self.score, 10, 10, love.graphics.getWidth(), 'left')
    -- love.graphics.printf("Wave: " .. self.wave, 10, 30, love.graphics.getWidth(), 'left')
    -- love.graphics.printf("Time: " .. math.floor(self.gameTime), 10, 50, love.graphics.getWidth(), 'left')
    
    -- Draw enemies
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    
    -- Draw bosses
    for _, boss in ipairs(self.bosses) do
        boss:draw()
    end
end

function GameState:spawnEnemy(player)
    if #self.enemies >= self.maxEnemies then return end
    
    local angle = math.random() * math.pi * 2
    local distance = self.enemySpawnRadius
    local x = player.x + math.cos(angle) * distance
    local y = player.y + math.sin(angle) * distance
    
    table.insert(self.enemies, Enemy:new(x, y, self.wave))
end

function GameState:spawnBoss(player)
    local angle = math.random() * math.pi * 2
    local distance = self.enemySpawnRadius
    local x = player.x + math.cos(angle) * distance
    local y = player.y + math.sin(angle) * distance
    
    table.insert(self.bosses, Boss:new(x, y, self.wave))
    self.sounds.bossSpawn:play()
end

function GameState:checkSpawnTimers(player)
    if self.spawnTimer >= self.spawnInterval then
        self.spawnTimer = 0
        self:spawnEnemy(player)
    end
    
    -- Only spawn bosses after the threshold wave
    if self.wave >= self.bossWaveThreshold and math.floor(self.gameTime) % self.bossSpawnInterval == 0 and self.gameTime > 0 then
        self:spawnBoss(player)
    end
end

return GameState 
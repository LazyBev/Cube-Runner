local WaveManager = {}
local Enemy = require("entities.enemy")

-- Wave configuration
local config = {
    baseEnemies = 5,
    enemyIncrease = 2,
    shopInterval = 5,
    spawnInterval = 1.0
}

local currentWave = 1
local spawnTimer = 0
local enemiesSpawned = 0
local totalEnemies = 0
local waveComplete = false
local gameState = nil

function WaveManager.init(state)
    gameState = state
    currentWave = 1
    spawnTimer = 0
    enemiesSpawned = 0
    totalEnemies = 0
    waveComplete = false
    math.randomseed(os.time())
end

function WaveManager.update(dt)
    if waveComplete then return end
    
    spawnTimer = spawnTimer + dt
    if spawnTimer >= config.spawnInterval and enemiesSpawned < totalEnemies then
        spawnTimer = 0
        local x, y = WaveManager.getRandomSpawnPosition()
        local enemyType = math.random() < 0.7 and "small" or "large"
        table.insert(gameState.enemies, Enemy.new(enemyType, x, y))
        enemiesSpawned = enemiesSpawned + 1
    end
end

function WaveManager.startWave(wave)
    currentWave = wave
    spawnTimer = 0
    enemiesSpawned = 0
    totalEnemies = config.baseEnemies + (wave - 1) * config.enemyIncrease
    waveComplete = false
end

function WaveManager.isWaveComplete()
    return waveComplete
end

function WaveManager.getRandomSpawnPosition()
    local side = math.random(1, 4)
    local x, y
    
    if side == 1 then -- Top
        x = math.random(0, love.graphics.getWidth())
        y = -50
    elseif side == 2 then -- Right
        x = love.graphics.getWidth() + 50
        y = math.random(0, love.graphics.getHeight())
    elseif side == 3 then -- Bottom
        x = math.random(0, love.graphics.getWidth())
        y = love.graphics.getHeight() + 50
    else -- Left
        x = -50
        y = math.random(0, love.graphics.getHeight())
    end
    
    return x, y
end

function WaveManager.getWaveInfo()
    return {
        number = currentWave,
        enemies = totalEnemies,
        spawned = enemiesSpawned,
        remaining = totalEnemies - enemiesSpawned
    }
end

return WaveManager 
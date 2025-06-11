-- Game states
local states = {
    MENU = "menu",
    GAME = "game",
    SHOP = "shop",
    CLASS_SELECT = "class_select"
}

-- Game configuration
local config = {
    window = {
        width = 1280,
        height = 720,
        title = "Cube Runner"
    },
    player = {
        size = 40,
        speed = 300,
        dashSpeed = 800,
        dashDuration = 0.2,
        dashCooldown = 1.0
    },
    wave = {
        baseEnemies = 5,
        enemyIncrease = 2,
        shopInterval = 5
    }
}

-- Game state
local gameState = {
    currentState = states.MENU,
    score = 0,
    wave = 1,
    enemies = {},
    player = nil,
    shop = nil,
    selectedClass = nil,
    coins = 0,
    gameTime = 0,
    settings = nil,
    waveTimer = 0,
    gameOver = false,
    canvas = nil,
    postProcessCanvas = nil,
    glitchTimer = 0,
    glitchIntensity = 0
}

-- Load required modules
local Player = require("entities.player")
local Enemy = require("entities.enemy")
local Shop = require("systems.shop")
local WaveManager = require("systems.wave_manager")
local ClassSystem = require("systems.class_system")
local UI = require("ui.ui")
local AudioManager = require("systems.audio_manager")
local MenuSystem = require("systems.menu_system")
local ShaderManager = require("systems.shader_manager")
local Shaders = require("shaders")

function love.load()
    -- Set up the window
    love.window.setMode(config.window.width, config.window.height)
    love.window.setTitle(config.window.title)
    
    -- Initialize systems
    Enemy.init(gameState)
    WaveManager.init(gameState)
    Shop.init()
    ClassSystem.init()
    UI.init()
    AudioManager.init()
    MenuSystem.init()
    ShaderManager.init()
    
    -- Start with menu music
    AudioManager.playMusic("menu")
    
    -- Create canvases for post-processing
    gameState.canvas = love.graphics.newCanvas()
    gameState.postProcessCanvas = love.graphics.newCanvas()
    
    -- Initialize game state
    gameState.player = Player.new("VOID_KNIGHT")
    
    -- Load settings
    local settings = MenuSystem.getSettings()
    
    -- Set up cyberpunk font
    love.graphics.setFont(love.graphics.newFont(24))
end

function love.update(dt)
    -- Update shader manager
    ShaderManager.update(dt)
    
    if gameState.currentState == states.MENU then
        -- Menu state is handled by MenuSystem
        return
    elseif gameState.currentState == states.CLASS_SELECT then
        ClassSystem.update(dt)
    elseif gameState.currentState == states.GAME then
        -- Update game time
        gameState.gameTime = gameState.gameTime + dt
        
        -- Update player
        if gameState.player then
            gameState.player:update(dt)
        end
        
        -- Update enemies
        for i = #gameState.enemies, 1, -1 do
            local enemy = gameState.enemies[i]
            enemy:update(dt)
            
            -- Check collision with player
            if gameState.player and not gameState.player.isDashing then
                local dx = enemy.x - gameState.player.x
                local dy = enemy.y - gameState.player.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance < enemy.size + gameState.player.size then
                    gameState.player:takeDamage(enemy.damage)
                    table.remove(gameState.enemies, i)
                    AudioManager.playSound("hit")
                end
            end
            
            -- Remove dead enemies
            if enemy.health <= 0 then
                gameState.score = gameState.score + enemy.scoreValue
                gameState.coins = gameState.coins + enemy.coinValue
                table.remove(gameState.enemies, i)
                AudioManager.playSound("hit")
            end
        end
        
        -- Update wave manager
        WaveManager.update(dt)
        
        -- Check for wave completion
        if #gameState.enemies == 0 and WaveManager.isWaveComplete() then
            gameState.currentState = states.SHOP
            AudioManager.playMusic("shop")
        end
        
        -- Spawn enemies
        gameState.waveTimer = gameState.waveTimer - dt
        if gameState.waveTimer <= 0 then
            spawnWave()
        end
    elseif gameState.currentState == states.SHOP then
        Shop.update(dt)
    end
end

function love.draw()
    if gameState.currentState == states.MENU then
        MenuSystem.draw()
    elseif gameState.currentState == states.CLASS_SELECT then
        ClassSystem.draw()
    elseif gameState.currentState == states.GAME then
        -- Draw to main canvas
        love.graphics.setCanvas(gameState.canvas)
        love.graphics.clear()
        
        -- Draw game elements
        if not gameState.gameOver then
            -- Draw enemies
            for _, enemy in ipairs(gameState.enemies) do
                enemy:draw()
            end
            
            -- Draw player
            gameState.player:draw()
        end
        
        -- Draw UI
        drawUI()
        
        -- Reset canvas
        love.graphics.setCanvas()
        
        -- Apply post-processing
        love.graphics.setCanvas(gameState.postProcessCanvas)
        love.graphics.clear()
        
        -- Draw main canvas with screen effect
        local screenEffect = Shaders.applyScreenEffect(1.0)
        love.graphics.setShader(screenEffect)
        love.graphics.draw(gameState.canvas)
        love.graphics.setShader()
        
        -- Draw post-processed result
        love.graphics.setCanvas()
        love.graphics.draw(gameState.postProcessCanvas)
    elseif gameState.currentState == states.SHOP then
        Shop.draw()
    end
end

function love.keypressed(key)
    if gameState.currentState == states.MENU then
        MenuSystem.handleInput(key)
    elseif gameState.currentState == states.CLASS_SELECT then
        if key == "return" then
            local selectedClass = ClassSystem.getSelectedClass()
            if selectedClass then
                gameState.player = Player.new(selectedClass.name)
                gameState.currentState = states.GAME
                gameState.wave = 1
                gameState.score = 0
                gameState.coins = 0
                gameState.gameTime = 0
                gameState.enemies = {}
                WaveManager.startWave(gameState.wave)
                AudioManager.playMusic("gameplay")
            end
        end
    elseif gameState.currentState == states.GAME then
        if key == "escape" then
            gameState.currentState = states.MENU
            AudioManager.playMusic("menu")
        elseif key == gameState.settings.keybinds.dash and gameState.player then
            gameState.player:dash()
            AudioManager.playSound("dash")
        elseif key == "space" and not gameState.gameOver then
            gameState.player:dash()
        end
    elseif gameState.currentState == states.SHOP then
        if key == "return" then
            local selectedUpgrade = Shop.getSelectedUpgrade()
            if selectedUpgrade then
                if gameState.coins >= selectedUpgrade.cost then
                    gameState.coins = gameState.coins - selectedUpgrade.cost
                    gameState.player:applyUpgrade(selectedUpgrade)
                    AudioManager.playSound("menuSelect")
                end
            else
                gameState.wave = gameState.wave + 1
                gameState.currentState = states.GAME
                gameState.enemies = {}
                WaveManager.startWave(gameState.wave)
                AudioManager.playMusic("gameplay")
            end
        end
    end
end

function love.mousepressed(x, y, button)
    if gameState.currentState == states.SHOP then
        Shop.handleClick(x, y, button)
        if button == 1 then
            AudioManager.playSound("menuSelect")
        end
    elseif gameState.currentState == states.CLASS_SELECT then
        ClassSystem.handleClick(x, y, button)
        if button == 1 then
            AudioManager.playSound("menuSelect")
        end
    end
end

function love.mousemoved(x, y)
    ShaderManager.setMousePosition(x, y)
end

-- Handle state changes
function changeState(newState)
    if newState == states.GAME then
        AudioManager.playMusic("gameplay")
    elseif newState == states.SHOP then
        AudioManager.playMusic("menu")
    elseif newState == states.CLASS_SELECT then
        AudioManager.playMusic("menu")
    end
    gameState.currentState = newState
end

-- Handle window resize
function love.resize(w, h)
    -- Update any size-dependent calculations
end

-- Spawn a wave of enemies
function spawnWave()
    local numEnemies = math.floor(5 + gameState.wave * 2)
    for i = 1, numEnemies do
        local x = love.math.random(50, love.graphics.getWidth() - 50)
        local y = love.math.random(50, love.graphics.getHeight() - 50)
        local type = love.math.random() < 0.7 and "small" or "large"
        table.insert(gameState.enemies, Enemy.new(type, x, y))
    end
    
    gameState.wave = gameState.wave + 1
    gameState.waveTimer = 10
end

-- Draw UI elements
function drawUI()
    -- Draw background overlay for UI elements
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 200, 150)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 200, 0, 200, 50)
    
    -- Draw score and coins with modern styling
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print("Score: " .. gameState.score, 20, 20)
    love.graphics.print("Coins: " .. gameState.coins, 20, 50)
    
    -- Draw wave with pulsing effect
    local pulse = math.sin(love.timer.getTime() * 3) * 0.1 + 0.9
    love.graphics.setColor(0.8, 0.8, 1, pulse)
    love.graphics.print("Wave: " .. gameState.wave, love.graphics.getWidth() - 180, 20)
    
    -- Draw player stats if available
    if gameState.player then
        -- Health bar
        local healthPercent = gameState.player.health / gameState.player.maxHealth
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", 20, 90, 160, 20)
        love.graphics.setColor(0.2 + healthPercent * 0.8, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", 20, 90, 160 * healthPercent, 20)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("HP: " .. gameState.player.health .. "/" .. gameState.player.maxHealth, 25, 92)
    end
    
    -- Draw game over screen with enhanced styling
    if gameState.gameOver then
        -- Fade overlay
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Game over text with glow effect
        local glow = math.sin(love.timer.getTime() * 2) * 0.1 + 0.9
        love.graphics.setColor(1, 0.2, 0.2, glow)
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.printf("GAME OVER", 0, love.graphics.getHeight()/2 - 100, love.graphics.getWidth(), "center")
        
        -- Stats with modern styling
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.printf("Final Score: " .. gameState.score, 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")
        love.graphics.printf("Waves Survived: " .. gameState.wave, 0, love.graphics.getHeight()/2 + 40, love.graphics.getWidth(), "center")
        
        -- Restart prompt with pulsing effect
        local pulse = math.sin(love.timer.getTime() * 3) * 0.1 + 0.9
        love.graphics.setColor(0.7, 0.7, 0.7, pulse)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("Press ESC to return to menu", 0, love.graphics.getHeight()/2 + 100, love.graphics.getWidth(), "center")
    end
end 
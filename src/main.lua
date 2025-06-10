-- Import modules
local Constants = require("utils.constants")
local Player = require("entities.player")
local Obstacles = require("entities.obstacles")
local Particles = require("entities.particles")
local Menu = require("ui.menu")
local HUD = require("ui.hud")
local Animations = require("ui.animations")
local WinShader = require("shaders.win_shader")
local PostProcess = require("shaders.post_process")
local Camera = require("core.camera")
local Audio = require("core.audio")
local Network = require("core.network")
local World = require("core.world")

-- Use new RPG player system
local PlayerEntity = require("entities.player")

-- Game state
local gameState = {
    currentState = Constants.STATES.MENU,
    currentMode = Constants.MODES.REGULAR,
    selectedOption = 1,
    menuOptions = Constants.MENU_OPTIONS,
    players = {},
    obstacles = {},
    particles = {},
    winAnimation = {
        active = false,
        elapsed = 0,
        scale = 1,
        rotation = 0,
        textAlpha = 1,
        textGlow = 0,
        cameraOffset = {x = 0, y = 0},
        particles = {},
        victoryBeams = {},
        sparkles = {},
        shader = WinShader
    },
    postProcess = {
        bloomIntensity = 0.7,
        vignetteIntensity = 0.4,
        colorGrade = {1.2, 1.1, 0.9},
        chromaticAberration = 0.003
    },
    gameTime = 0,
    combo = 0,
    maxCombo = 0,
    score = 0,
    highScore = 0,
    spawnTimer = 0,
    spawnInterval = 2,
    difficulty = 1,
    uiScale = 0.8,
    chat = {
        messages = {},
        input = "",
        visible = false
    }
}

-- Initialize game
function love.load()
    -- Set up window with fixed size
    love.window.setMode(960, 540, {
        resizable = false,
        vsync = true,
        fullscreen = false,
        msaa = 4
    })
    
    -- Set window title
    love.window.setTitle("Cube Runner MMORPG")
    
    -- Create render target
    gameState.renderTarget = love.graphics.newCanvas(960, 540, {
        msaa = 4,
        format = "rgba16f"
    })
    
    -- Initialize networking
    Network.initialize()
    
    -- Initialize world
    World.initialize()
    
    -- Create local player
    local localPlayer = Player.new(Player.CLASSES.WARRIOR)
    if Network.playerId then
        gameState.players[Network.playerId] = localPlayer
        -- Initialize player
        Player.initialize(localPlayer)
    else
        error("Failed to generate player ID")
    end
    
    -- Initialize camera with adjusted zoom
    Camera.initialize(1.2)
    
    -- Initialize audio
    Audio.initialize()
    
    -- Initialize post-processing
    PostProcess.initialize()
    
    -- Initialize HUD with compact layout
    HUD.updateLayout()
    
    -- Initialize menu
    Menu.initialize()
    
    -- Load high score
    if love.filesystem.getInfo("highscore.txt") then
        gameState.highScore = tonumber(love.filesystem.read("highscore.txt")) or 0
    end
end

-- Function to reset game state
function resetGameState()
    -- Reset players
    gameState.players = {}
    
    -- Reset obstacles
    gameState.obstacles = Obstacles.initialize()
    
    -- Reset game state variables
    gameState.gameTime = 0
    gameState.combo = 0
    gameState.maxCombo = 0
    gameState.score = 0
    gameState.winner = nil
    
    -- Reset win animation
    gameState.winAnimation = {
        active = false,
        elapsed = 0,
        scale = 1,
        rotation = 0,
        textAlpha = 1,
        textGlow = 0,
        cameraOffset = {x = 0, y = 0},
        particles = {},
        victoryBeams = {},
        sparkles = {},
        shader = WinShader
    }
    
    -- Reset camera
    Camera.initialize()
    
    -- Return to menu music
    Audio.playMusic("menu", 1.0)
end

-- Function to calculate game score
function calculateScore(gameState)
    local score = gameState.score or 0
    
    -- Add time bonus
    local timeBonus = math.floor(gameState.gameTime * 10)
    
    -- Add combo multiplier
    local comboMultiplier = 1 + (gameState.combo * 0.1)
    
    -- Calculate final score
    return math.floor((score + timeBonus) * comboMultiplier)
end

-- Update game state
function love.update(dt)
    -- Update game state
    gameState.gameTime = gameState.gameTime + dt
    
    -- Update networking
    Network.update(dt)
    
    -- Update world
    World.update(dt)
    
    -- Update HUD animations
    HUD.update(dt)
    
    -- Update all players
    for playerId, player in pairs(gameState.players) do
        if playerId == Network.playerId then
            -- Update local player
            Player.update(player, dt, gameState.obstacles)
        else
            -- Update remote players (interpolation)
            Player.interpolate(player, dt)
        end
    end
    
    -- Update obstacles
    for _, obstacle in ipairs(gameState.obstacles) do
        obstacle:update(dt)
    end
    
    -- Check collisions
    for _, player in pairs(gameState.players) do
        for _, obstacle in ipairs(gameState.obstacles) do
            if Player.checkCollision(player, obstacle) then
                player.health = player.health - obstacle.damage
                HUD.onHealthChange()
            end
        end
    end
    
    -- Update score
    local newScore = calculateScore(gameState)
    if newScore > gameState.score then
        gameState.score = newScore
        HUD.onScoreChange()
    end
    
    if gameState.currentState == Constants.STATES.MENU then
        -- Menu state updates
        Menu.update(gameState, dt)
    elseif gameState.currentState == Constants.STATES.PLAYING then
        -- Game state updates
        for playerId, player in pairs(gameState.players) do
            if playerId == Network.playerId then
                -- Update camera to follow local player
                Camera.setTarget(player.x, player.y)
                
                -- Add camera shake on dash
                if player.isDashing then
                    local shakeIntensity = math.min(10, player.dashSpeed / 50)
                    Camera.startShake(shakeIntensity, 0.1)
                    Particles.addDashParticles(player)
                end
            end
        end
    elseif gameState.currentState == Constants.STATES.WIN then
        -- Win animation updates
        Animations.updateWinAnimation(gameState.winAnimation, dt)
    end
end

-- Draw game
function love.draw()
    -- Start post-processing
    PostProcess.begin()
    
    -- Draw world
    World.draw()
    
    -- Draw all players
    for _, player in pairs(gameState.players) do
        Player.draw(player)
    end
    
    -- Draw obstacles
    for _, obstacle in ipairs(gameState.obstacles) do
        obstacle:draw()
    end
    
    -- Draw particles
    Particles.draw()
    
    -- Draw HUD
    HUD.draw(gameState)
    
    -- Draw chat if visible
    if gameState.chat.visible then
        drawChat()
    end
    
    -- End post-processing
    PostProcess.finish()
end

-- Handle keyboard input
function love.keypressed(key)
    if key == "escape" then
        if gameState.chat.visible then
            gameState.chat.visible = false
        else
            gameState.currentState = Constants.STATES.MENU
        end
    elseif key == "t" then
        gameState.chat.visible = not gameState.chat.visible
    elseif key == "f11" then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
        -- Restore window properties after fullscreen toggle
        if not fullscreen then
            love.window.setMode(960, 540, {
                resizable = false,
                vsync = true,
                fullscreen = false,
                msaa = 4
            })
        end
    end
    
    if gameState.currentState == Constants.STATES.MENU then
        Menu.handleInput(key, gameState)
    elseif gameState.currentState == Constants.STATES.PLAYING then
        for _, player in pairs(gameState.players) do
            if key == player.keybinds.dash then
                Player.startDash(player)
                Audio.playSound("dash", player.x, player.y)
            elseif key == player.keybinds.ability then
                Player.activateAbility(player)
                Audio.playSound("ability", player.x, player.y)
            end
        end
    elseif gameState.currentState == Constants.STATES.WIN then
        if key == "return" or key == "space" then
            gameState.currentState = Constants.STATES.MENU
            resetGameState()  -- Reset game state when returning to menu
            Audio.playMusic("menu", 1.0)
        end
    end
end

-- Handle mouse input
function love.mousepressed(x, y, button)
    if gameState.currentState == Constants.STATES.MENU then
        Menu.handleMouse(x, y, button, gameState)
    end
end

-- Handle window resize (removed since window is no longer resizable)
function love.resize(w, h)
    -- This function is kept empty since window is no longer resizable
end

-- Handle text input for chat
function love.textinput(t)
    if gameState.chat.visible then
        gameState.chat.input = gameState.chat.input .. t
    end
end

-- Draw chat interface
function drawChat()
    local chat = gameState.chat
    local font = love.graphics.getFont()
    local padding = 10
    local lineHeight = font:getHeight() + 5
    
    -- Draw chat background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 300, 200)
    
    -- Draw chat messages
    love.graphics.setColor(1, 1, 1, 1)
    for i, message in ipairs(chat.messages) do
        love.graphics.print(message, padding, padding + (i-1) * lineHeight)
    end
    
    -- Draw input box
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 0, 200 - lineHeight, 300, lineHeight)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(chat.input .. "|", padding, 200 - lineHeight)
end

-- Handle chat messages
function love.handlers.chat_message(message)
    table.insert(gameState.chat.messages, message)
    if #gameState.chat.messages > 10 then
        table.remove(gameState.chat.messages, 1)
    end
end

return gameState 
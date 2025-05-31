local player1 = {} -- Player 1
local player2 = {} -- Player 2
local particles = {}
local obstacles = {} -- New obstacle system
local camera = { x = 0, y = 0 }
local screenShake = { intensity = 0, duration = 0 }
local gameState = "menu" -- "menu", "playing", "gameover", "options", "customize_p1", "customize_p2", "class_select"
local winner = ""
local menuSelection = 1
local menuOptions = {"Start Game", "Player Options", "Controls", "Quit"}
local showingControls = false
local optionsSelection = 1
local optionsMenu = {"Customize Player 1", "Customize Player 2", "Back"}
local customizeSelection = 1
local customizeOptions = {"Name", "Color", "Keybinds", "Back"}
local currentPlayer = 1 -- 1 or 2
local inputMode = "" -- "name", "keybind"
local inputBuffer = ""
local keybindWaiting = ""
local gameMode = "regular" -- "regular" or "icey"
local modeSelection = 1
local modeOptions = {"Regular", "Icey", "Back"}
local showingModeSelect = false
local backgroundShader = ""
local time = 0

-- Initialize win animation
local winAnimation = {
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
    shader = nil
}

-- Class definitions
local classes = {
    {
        name = "Warrior",
        description = "A balanced fighter with a powerful dash attack",
        color = {0.8, 0.2, 0.2},
        ability = {
            name = "Power Dash",
            description = "Deals 50% more damage with dash attacks",
            cooldown = 0,
            active = false
        }
    },
    {
        name = "Mage",
        description = "A ranged fighter with a teleport ability",
        color = {0.2, 0.2, 0.8},
        ability = {
            name = "Teleport",
            description = "Instantly teleport to target location",
            cooldown = 0,
            active = false
        }
    },
    {
        name = "Rogue",
        description = "A fast fighter with a double dash ability",
        color = {0.2, 0.8, 0.2},
        ability = {
            name = "Double Dash",
            description = "Can dash twice in quick succession",
            cooldown = 0,
            active = false
        }
    },
    {
        name = "Tank",
        description = "A defensive fighter with a shield ability",
        color = {0.8, 0.8, 0.2},
        ability = {
            name = "Shield",
            description = "Temporarily reduces damage taken by 50%",
            cooldown = 0,
            active = false
        }
    }
}

local classSelection = 1
local classSelectPlayer = 1 -- Which player is selecting their class

local playerData = {
    {
        name = "Blue Player",
        color = {0.3, 0.7, 1},
        colorName = "blue",
        keybinds = {up = "w", down = "s", left = "a", right = "d", dash = "space", ability = "q"},
        class = nil,
        ability = nil
    },
    {
        name = "Red Player",
        color = {1, 0.3, 0.3},
        colorName = "red",
        keybinds = {up = "i", down = "k", left = "j", right = "l", dash = ";", ability = "p"},
        class = nil,
        ability = nil
    }
}

-- Add these variables at the top with other game state variables
local gameOverTransition = {
    active = false,
    duration = 0,
    maxDuration = 3.0,  -- Increased from 1.5 to 3.0 seconds
    timeScale = 1.0,    -- For slowing down the game
    fadeStart = 0.5     -- When to start fading (in seconds)
}

function createBackgroundShader()
    local vertexCode = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return transform_projection * vertex_position;
        }
    ]]

    local fragmentCode = [[
        uniform float time;
        uniform vec2 resolution;

        // Hash function for pseudo-random values
        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
        }

        // Noise function
        float noise(vec2 p) {
            vec2 i = floor(p);
            vec2 f = fract(p);

            float a = hash(i);
            float b = hash(i + vec2(1.0, 0.0));
            float c = hash(i + vec2(0.0, 1.0));
            float d = hash(i + vec2(1.0, 1.0));

            vec2 u = f * f * (3.0 - 2.0 * f);
            return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }

        // Fractal noise
        float fbm(vec2 p) {
            float value = 0.0;
            float amplitude = 0.5;
            for (int i = 0; i < 6; i++) {
                value += amplitude * noise(p);
                p *= 2.0;
                amplitude *= 0.5;
            }
            return value;
        }

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 uv = screen_coords / resolution;
            vec2 center = vec2(0.5, 0.5);

            // Create moving UV coordinates
            vec2 movingUV = uv + vec2(sin(time * 0.3), cos(time * 0.2)) * 0.1;

            // Multiple layers of animated patterns
            float layer1 = fbm(movingUV * 3.0 + time * 0.5);
            float layer2 = fbm(movingUV * 6.0 - time * 0.3);
            float layer3 = fbm(movingUV * 12.0 + time * 0.8);

            // Swirling pattern
            float angle = atan(uv.y - center.y, uv.x - center.x);
            float radius = length(uv - center);
            float spiral = sin(angle * 4.0 + radius * 12.0 - time * 2.0) * 0.5 + 0.5;

            // Pulsing rings
            float rings = sin(radius * 20.0 - time * 3.0) * 0.3 + 0.7;

            // Flowing waves across the screen
            float wave1 = sin(uv.x * 8.0 + time * 1.5) * 0.2;
            float wave2 = cos(uv.y * 6.0 - time * 2.0) * 0.15;
            float crossWave = sin((uv.x + uv.y) * 10.0 + time * 2.5) * 0.1;

            // Combine all patterns
            float combined = layer1 * 0.4 + layer2 * 0.3 + layer3 * 0.2 +
                           spiral * 0.3 + rings * 0.2 +
                           (wave1 + wave2 + crossWave) * 0.5;

            // Dynamic color palette that shifts over time
            vec3 color1 = vec3(0.1 + sin(time * 0.5) * 0.1,
                              0.2 + cos(time * 0.3) * 0.1,
                              0.4 + sin(time * 0.7) * 0.2);
            vec3 color2 = vec3(0.3 + cos(time * 0.4) * 0.2,
                              0.1 + sin(time * 0.6) * 0.1,
                              0.5 + cos(time * 0.8) * 0.15);
            vec3 color3 = vec3(0.2 + sin(time * 0.9) * 0.15,
                              0.3 + cos(time * 0.2) * 0.2,
                              0.6 + sin(time * 0.4) * 0.1);

            // Mix colors based on the combined pattern
            vec3 finalColor = mix(color1, color2, combined);
            finalColor = mix(finalColor, color3, layer3 * 0.6);

            // Add brightness variations
            finalColor *= (0.8 + combined * 0.4);

            // Animated sparkles/stars
            vec2 starUV = floor(uv * 80.0) / 80.0;
            float starNoise = hash(starUV + floor(time * 2.0));
            if (starNoise > 0.97) {
                float sparkleIntensity = sin(time * 10.0 + starNoise * 100.0) * 0.5 + 0.5;
                finalColor += vec3(0.2, 0.3, 0.6) * sparkleIntensity * 0.8;
            }

            // Edge vignette effect
            float vignette = 1.0 - pow(length(uv - center) * 1.2, 2.0);
            finalColor *= vignette;

            // Subtle screen-wide pulse
            float pulse = (sin(time * 1.2) + sin(time * 1.7) + sin(time * 2.1)) * 0.02 + 1.0;
            finalColor *= pulse;

            return vec4(finalColor, 1.0);
        }
    ]]

    backgroundShader = love.graphics.newShader(fragmentCode, vertexCode)
end

function drawBackground()
    if backgroundShader then
        love.graphics.setShader(backgroundShader)
        backgroundShader:send("time", time)
        backgroundShader:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})

        -- Draw a fullscreen rectangle
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.setShader()
    else
        -- Fallback if shader fails
        love.graphics.setColor(0.1, 0.1, 0.2)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function drawControlsScreen()
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2

    drawBackground()

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CONTROLS", 0, centerY - 150, love.graphics.getWidth(), "center")

    local controls = {
        playerData[1].name .. ":",
        "  Move: " .. string.upper(playerData[1].keybinds.up) ..
        string.upper(playerData[1].keybinds.left) ..
        string.upper(playerData[1].keybinds.down) ..
        string.upper(playerData[1].keybinds.right),
        "  Dash: " .. string.upper(playerData[1].keybinds.dash),
        "",
        playerData[2].name .. ":",
        "  Move: " .. string.upper(playerData[2].keybinds.up) ..
        string.upper(playerData[2].keybinds.left) ..
        string.upper(playerData[2].keybinds.down) ..
        string.upper(playerData[2].keybinds.right),
        "  Dash: " .. string.upper(playerData[2].keybinds.dash),
        "",
        "Press ESC or ENTER to go back"
    }

    for i, line in ipairs(controls) do
        love.graphics.printf(line, 0, centerY - 80 + (i - 1) * 20, love.graphics.getWidth(), "center")
    end
end

local colorPresets = {
    {name = "Blue", color = {0.3, 0.7, 1}},
    {name = "Red", color = {1, 0.3, 0.3}},
    {name = "Green", color = {0.3, 1, 0.3}},
    {name = "Purple", color = {0.8, 0.3, 1}},
    {name = "Orange", color = {1, 0.6, 0.2}},
    {name = "Cyan", color = {0.2, 1, 1}},
    {name = "Yellow", color = {1, 1, 0.3}},
    {name = "Pink", color = {1, 0.4, 0.8}}
}

function main()
    -- Initialize game state
    initializeGame()

    -- Create background shader
    createBackgroundShader()

    -- Start the main game loop (LÖVE2D handles this automatically)
    print("Cube Dash Battle initialized successfully!")
end

function initializePlayer(player, x, y, color, colorName)
    player.x = x
    player.y = y
    player.size = 20
    player.vx = 0
    player.vy = 0
    player.speed = 120
    -- Set friction based on game mode
    if gameMode == "icey" then
        player.friction = 0.88 -- Much more slippery
    else
        player.friction = 0.70 -- Normal friction
    end
    player.color = color
    player.colorName = colorName

    -- Health system
    player.health = 100
    player.maxHealth = 100
    player.invulnerable = 0
    player.invulnerabilityTime = 1.0

    -- Dash properties
    player.dashDistance = 120
    player.dashCooldown = 0
    player.dashCooldownMax = 0.8
    player.isDashing = false
    player.dashDuration = 0
    player.dashDurationMax = 0.25
    player.dashStartPos = {x = 0, y = 0}
    player.dashTargetPos = {x = 0, y = 0}
    player.dashDirection = {x = 0, y = 0}
    player.beamActive = false

    -- Visual effects
    player.trail = {}
    player.glowIntensity = 0

    -- Class-specific properties
    player.abilityCooldown = 0
    player.abilityActive = false
    player.abilityUses = 0
    player.abilityMaxUses = 0
    player.abilityDuration = 0  -- Added this line
    player.doubleDashAvailable = false
    player.shieldActive = false
end

function drawModeSelect()
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECT GAME MODE", 0, centerY - 100, love.graphics.getWidth(), "center")

    -- Mode descriptions
    local descriptions = {
        "Normal movement and friction",
        "Slippery ice physics - harder to stop!",
        ""
    }

    -- Mode options
    for i, option in ipairs(modeOptions) do
        local y = centerY - 20 + (i - 1) * 50

        if i == modeSelection then
            love.graphics.setColor(0.3, 0.7, 1)
            love.graphics.rectangle("fill", centerX - 120, y - 10, 240, 40)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("> " .. option .. " <", 0, y, love.graphics.getWidth(), "center")

            -- Show description for selected mode
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf(descriptions[i], love.graphics.getWidth() / 2 - 400, love.graphics.getHeight() / 2 + 150, love.graphics.getWidth(), "center")
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf(option, 0, y, love.graphics.getWidth(), "center")
        end
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("W/S to navigate, SPACE/Enter to select, ESC to go back", 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
end

function initializeObstacles()
    obstacles = {}
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Add various obstacles
    table.insert(obstacles, {x = screenWidth/2 - 25, y = screenHeight/2 - 25, width = 50, height = 50})
    table.insert(obstacles, {x = screenWidth/2 - 75, y = 200, width = 150, height = 20})
    table.insert(obstacles, {x = screenWidth/2 - 75, y = screenHeight - 220, width = 150, height = 20})
end

function checkObstacleCollision(x, y, size)
    for _, obstacle in ipairs(obstacles) do
        if x - size/2 < obstacle.x + obstacle.width and
           x + size/2 > obstacle.x and
           y - size/2 < obstacle.y + obstacle.height and
           y + size/2 > obstacle.y then
            return true
        end
    end
    return false
end

function findValidDashTarget(player, dirX, dirY)
    local startX = player.x
    local startY = player.y
    local targetX = startX + dirX * player.dashDistance
    local targetY = startY + dirY * player.dashDistance

    -- Check boundaries first
    local borderSize = 10
    targetX = math.max(player.size/2 + borderSize, math.min(love.graphics.getWidth() - player.size/2 - borderSize, targetX))
    targetY = math.max(player.size/2 + borderSize, math.min(love.graphics.getHeight() - player.size/2 - borderSize, targetY))

    -- Check for obstacle collisions along the dash path
    local steps = 20
    for i = 1, steps do
        local progress = i / steps
        local checkX = startX + (targetX - startX) * progress
        local checkY = startY + (targetY - startY) * progress

        if checkObstacleCollision(checkX, checkY, player.size) then
            -- Find the last valid position before collision
            local validProgress = math.max(0, (i - 1) / steps)
            targetX = startX + (targetX - startX) * validProgress
            targetY = startY + (targetY - startY) * validProgress
            break
        end
    end

    return targetX, targetY
end

function initializeGame()
    -- Set up window
    love.window.setTitle("Cube Runner")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)

    -- Initialize game state variables - START WITH MENU
    gameState = "menu"
    winner = ""
    particles = {}
    camera = { x = 0, y = 0 }
    screenShake = { intensity = 0, duration = 0 }

    -- Initialize obstacles
    initializeObstacles()

    -- Initialize players but don't start the game yet
    initializePlayer(player1, 200, 300, playerData[1].color, playerData[1].colorName)
    initializePlayer(player2, 600, 300, playerData[2].color, playerData[2].colorName)

    -- Create victory shader
    createVictoryShader()
end

function initializeMenu()
    gameState = "menu"
    menuSelection = 1
    showingControls = false
    inputMode = ""
    inputBuffer = ""
    keybindWaiting = ""
end

function love.load()
    main()
end

function love.update(dt)
    -- Update global time
    time = time + dt

    if gameState == "menu" or gameState == "options" or
       gameState == "customize_p1" or gameState == "customize_p2" then
        return
    elseif gameState == "gameover" then
        updateWinAnimation(dt)
        return
    end

    -- Apply time scale for game over transition
    local scaledDt = dt
    if gameOverTransition.active then
        scaledDt = dt * gameOverTransition.timeScale
        gameOverTransition.duration = gameOverTransition.duration + dt
        
        -- Gradually slow down the game more dramatically
        gameOverTransition.timeScale = math.max(0.05, 1 - (gameOverTransition.duration / gameOverTransition.maxDuration) * 1.5)
        
        -- When transition is complete, start win animation
        if gameOverTransition.duration >= gameOverTransition.maxDuration then
            gameState = "gameover"
            gameOverTransition.active = false
            winAnimation.active = true
            winAnimation.elapsed = 0
        end
    end

    -- Update both players
    updatePlayer(player1, scaledDt, playerData[1].keybinds)
    updatePlayer(player2, scaledDt, playerData[2].keybinds)

    -- Check beam collisions
    checkBeamCollisions()

    -- Update particles
    updateParticles(scaledDt)

    camera.x = 0
    camera.y = 0

    -- Update screen shake
    if screenShake.duration > 0 then
        screenShake.duration = screenShake.duration - scaledDt
        if screenShake.duration <= 0 then
            screenShake.intensity = 0
        end
    end
end

function updatePlayer(player, dt, keybinds)
    local moveX, moveY = 0, 0
    local dashKey = false
    local abilityKey = false

    if love.keyboard.isDown(keybinds.left) then moveX = moveX - 1 end
    if love.keyboard.isDown(keybinds.right) then moveX = moveX + 1 end
    if love.keyboard.isDown(keybinds.up) then moveY = moveY - 1 end
    if love.keyboard.isDown(keybinds.down) then moveY = moveY + 1 end
    dashKey = love.keyboard.isDown(keybinds.dash)
    abilityKey = love.keyboard.isDown(keybinds.ability)

    -- Normalize diagonal movement
    if moveX ~= 0 and moveY ~= 0 then
        moveX = moveX * 0.707
        moveY = moveY * 0.707
    end

    -- Update ability cooldown
    if player.abilityCooldown > 0 then
        player.abilityCooldown = player.abilityCooldown - dt
    end

    -- Handle ability activation
    if abilityKey and player.abilityCooldown <= 0 and not player.abilityActive then
        activateAbility(player)
    end

    -- Update ability duration
    if player.abilityActive then
        player.abilityDuration = player.abilityDuration - dt
        if player.abilityDuration <= 0 then
            deactivateAbility(player)
        end
    end

    -- Update dash cooldown
    if player.dashCooldown > 0 then
        player.dashCooldown = player.dashCooldown - dt
    end

    -- Update invulnerability
    if player.invulnerable > 0 then
        player.invulnerable = player.invulnerable - dt
    end

    -- Handle dash input
    if dashKey and player.dashCooldown <= 0 and not player.isDashing then
        -- If no direction is pressed, use the last known velocity direction
        if moveX == 0 and moveY == 0 then
            if player.vx ~= 0 or player.vy ~= 0 then
                local length = math.sqrt(player.vx * player.vx + player.vy * player.vy)
                if length > 0 then
                    moveX = player.vx / length
                    moveY = player.vy / length
                else
                    -- If no velocity, use the last known dash direction or default to right
                    if player.dashDirection.x ~= 0 or player.dashDirection.y ~= 0 then
                        moveX = player.dashDirection.x
                        moveY = player.dashDirection.y
                    else
                        moveX = 1
                        moveY = 0
                    end
                end
            else
                -- If no velocity and no last dash direction, default to right
                moveX = 1
                moveY = 0
            end
        end
        
        startDash(player, moveX, moveY)
    end

    -- Update dash
    if player.isDashing then
        player.dashDuration = player.dashDuration - dt
        if player.dashDuration <= 0 then
            player.x = player.dashTargetPos.x
            player.y = player.dashTargetPos.y
            player.vx = 0
            player.vy = 0
            player.isDashing = false
            player.beamActive = false
            player.glowIntensity = 0
        else
            local progress = 1 - (player.dashDuration / player.dashDurationMax)
            local easedProgress = 1 - math.pow(1 - progress, 3)

            player.x = player.dashStartPos.x + (player.dashTargetPos.x - player.dashStartPos.x) * easedProgress
            player.y = player.dashStartPos.y + (player.dashTargetPos.y - player.dashStartPos.y) * easedProgress

            player.vx = 0
            player.vy = 0
            player.glowIntensity = 1
            player.beamActive = true
            addDashParticles(player)
        end
    else
        player.vx = player.vx + moveX * player.speed * dt
        player.vy = player.vy + moveY * player.speed * dt
        player.vx = player.vx * player.friction
        player.vy = player.vy * player.friction
        player.beamActive = false
    end

    -- Update position (only when not dashing)
    if not player.isDashing then
        local newX = player.x + player.vx
        local newY = player.y + player.vy

        -- Check obstacle collisions for movement
        if not checkObstacleCollision(newX, player.y, player.size) then
            player.x = newX
        else
            player.vx = 0
        end

        if not checkObstacleCollision(player.x, newY, player.size) then
            player.y = newY
        else
            player.vy = 0
        end

        -- Boundary checking
        local borderSize = 10
        if player.x < player.size/2 + borderSize then
            player.x = player.size/2 + borderSize
            player.vx = 0
        elseif player.x > love.graphics.getWidth() - player.size/2 - borderSize then
            player.x = love.graphics.getWidth() - player.size/2 - borderSize
            player.vx = 0
        end

        if player.y < player.size/2 + borderSize then
            player.y = player.size/2 + borderSize
            player.vy = 0
        elseif player.y > love.graphics.getHeight() - player.size/2 - borderSize then
            player.y = love.graphics.getHeight() - player.size/2 - borderSize
            player.vy = 0
        end
    end

    updateTrail(player, dt)
end

function startDash(player, dirX, dirY)
    player.isDashing = true
    player.dashDuration = player.dashDurationMax
    player.dashCooldown = player.dashCooldownMax
    player.dashDirection.x = dirX
    player.dashDirection.y = dirY

    -- Calculate start position
    player.dashStartPos.x = player.x
    player.dashStartPos.y = player.y

    -- Find valid dash target considering obstacles
    local targetX, targetY = findValidDashTarget(player, dirX, dirY)
    player.dashTargetPos.x = targetX
    player.dashTargetPos.y = targetY

    -- Screen shake effect
    screenShake.intensity = 3
    screenShake.duration = 0.1

    -- Add trail point
    table.insert(player.trail, {
        x = player.x,
        y = player.y,
        life = 0.5,
        maxLife = 0.5
    })

    -- Handle ability uses
    if player.abilityActive then
        player.abilityUses = player.abilityUses - 1
        if player.abilityUses <= 0 then
            deactivateAbility(player)
        end
    end

    -- Handle double dash
    if player.doubleDashAvailable then
        player.abilityUses = player.abilityUses - 1
        if player.abilityUses <= 0 then
            player.doubleDashAvailable = false
        end
    end
end

function checkBeamCollisions()
    -- Check if player1's beam hits player2
    if player1.beamActive and player2.invulnerable <= 0 then
        if isBeamHitting(player1, player2) then
            damagePlayer(player2, 25)
        end
    end

    -- Check if player2's beam hits player1
    if player2.beamActive and player1.invulnerable <= 0 then
        if isBeamHitting(player2, player1) then
            damagePlayer(player1, 25)
        end
    end
end

function isBeamHitting(attacker, target)
    -- Check if the target is within the beam path
    local beamWidth = 15

    -- Get beam start and end points
    local startX = attacker.dashStartPos.x
    local startY = attacker.dashStartPos.y
    local endX = attacker.dashTargetPos.x
    local endY = attacker.dashTargetPos.y

    -- Calculate distance from target to beam line
    local distance = pointToLineDistance(target.x, target.y, startX, startY, endX, endY)

    -- Check if target is within beam width and along the beam path
    if distance <= beamWidth then
        -- Check if target is between start and end points (with some tolerance)
        local beamLength = math.sqrt((endX - startX)^2 + (endY - startY)^2)
        local distToStart = math.sqrt((target.x - startX)^2 + (target.y - startY)^2)
        local distToEnd = math.sqrt((target.x - endX)^2 + (target.y - endY)^2)

        return distToStart <= beamLength + 20 and distToEnd <= beamLength + 20
    end

    return false
end

function pointToLineDistance(px, py, x1, y1, x2, y2)
    local A = px - x1
    local B = py - y1
    local C = x2 - x1
    local D = y2 - y1

    local dot = A * C + B * D
    local lenSq = C * C + D * D

    if lenSq == 0 then
        return math.sqrt(A * A + B * B)
    end

    local param = dot / lenSq

    local xx, yy
    if param < 0 then
        xx, yy = x1, y1
    elseif param > 1 then
        xx, yy = x2, y2
    else
        xx = x1 + param * C
        yy = y1 + param * D
    end

    local dx = px - xx
    local dy = py - yy
    return math.sqrt(dx * dx + dy * dy)
end

function damagePlayer(player, damage)
    -- Apply shield reduction if active
    if player.shieldActive then
        damage = damage * 0.5
        player.abilityUses = player.abilityUses - 1
        if player.abilityUses <= 0 then
            deactivateAbility(player)
        end
    end

    -- Check if the attacker is a Warrior with active Power Dash
    local attacker = (player == player1) and player2 or player1
    local attackerIndex = (attacker == player1) and 1 or 2
    if attacker.beamActive and playerData[attackerIndex].class.name == "Warrior" and attacker.abilityActive then
        damage = damage * 1.5 -- 50% more damage with Power Dash
    end

    player.health = player.health - damage
    player.invulnerable = player.invulnerabilityTime

    -- Screen shake on hit
    screenShake.intensity = 8
    screenShake.duration = 0.2

    -- Add hit particles
    for i = 1, 8 do
        table.insert(particles, {
            x = player.x + love.math.random(-15, 15),
            y = player.y + love.math.random(-15, 15),
            vx = love.math.random(-100, 100),
            vy = love.math.random(-100, 100),
            life = 0.8,
            maxLife = 0.8,
            size = love.math.random(3, 6),
            color = {1, 0.3, 0.3}
        })
    end
    
    -- Check for game over and start transition
    if player.health <= 0 then
        -- Start game over transition
        gameOverTransition.active = true
        gameOverTransition.duration = 0
        gameOverTransition.timeScale = 1.0
        
        -- Set winner
        if player == player1 then
            winner = playerData[2].name .. " Wins!"
            createWinParticles(player2.x, player2.y, player2.color)
        else
            winner = playerData[1].name .. " Wins!"
            createWinParticles(player1.x, player1.y, player1.color)
        end
    end
end

function addDashParticles(player)
    for i = 1, 2 do
        table.insert(particles, {
            x = player.x + love.math.random(-10, 10),
            y = player.y + love.math.random(-10, 10),
            vx = love.math.random(-50, 50),
            vy = love.math.random(-50, 50),
            life = 0.5,
            maxLife = 0.5,
            size = love.math.random(2, 4),
            color = player.color
        })
    end
end

function updateTrail(player, dt)
    for i = #player.trail, 1, -1 do
        local trail = player.trail[i]
        trail.life = trail.life - dt
        if trail.life <= 0 then
            table.remove(player.trail, i)
        end
    end
end

function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = p.vx * 0.95
        p.vy = p.vy * 0.95
        p.life = p.life - dt

        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

function love.draw()
    if gameState == "menu" then
        drawBackground()
        drawMenu()
        return
    elseif gameState == "options" then
        drawBackground()
        drawOptionsMenu()
        return
    elseif gameState == "customize_p1" or gameState == "customize_p2" then
        drawCustomizeMenu()
        return
    elseif gameState == "class_select" then
        drawClassSelect()
        return
    elseif gameState == "gameover" then
        drawGameOver()
        return
    end

    -- Game rendering code
    local shakeX = 0
    local shakeY = 0
    if screenShake.duration > 0 then
        shakeX = love.math.random(-screenShake.intensity, screenShake.intensity)
        shakeY = love.math.random(-screenShake.intensity, screenShake.intensity)
    end

    love.graphics.push()
    love.graphics.translate(-camera.x + shakeX, -camera.y + shakeY)

    -- Draw borders
    local borderSize = 10
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), borderSize)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - borderSize, love.graphics.getWidth(), borderSize)
    love.graphics.rectangle("fill", 0, 0, borderSize, love.graphics.getHeight())
    love.graphics.rectangle("fill", love.graphics.getWidth() - borderSize, 0, borderSize, love.graphics.getHeight())

    -- Draw obstacles
    love.graphics.setColor(0.6, 0.6, 0.7)
    for _, obstacle in ipairs(obstacles) do
        love.graphics.rectangle("fill", obstacle.x, obstacle.y, obstacle.width, obstacle.height)
        -- Add a subtle border to make obstacles more visible
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.rectangle("line", obstacle.x, obstacle.y, obstacle.width, obstacle.height)
        love.graphics.setColor(0.6, 0.6, 0.7)
    end

    drawBeam(player1)
    drawBeam(player2)
    drawTrail(player1)
    drawTrail(player2)

    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end

    drawPlayer(player1)
    drawPlayer(player2)

    love.graphics.pop()
    drawUI()

    -- Draw transition overlay if active
    if gameOverTransition.active then
        local alpha = 0
        if gameOverTransition.duration >= gameOverTransition.fadeStart then
            -- Calculate fade alpha based on remaining time after fadeStart
            local fadeProgress = (gameOverTransition.duration - gameOverTransition.fadeStart) / 
                               (gameOverTransition.maxDuration - gameOverTransition.fadeStart)
            alpha = fadeProgress * 0.7  -- Max opacity of 0.7
        end
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function drawMenu()
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2

    if showingControls then
        drawControlsScreen()
        return
    end

    if showingModeSelect then
        drawModeSelect()
        return
    end

    -- Animated background
    love.graphics.setColor(0.2, 0.3, 0.5, 0.3)
    for i = 1, 20 do
        local time = love.timer.getTime()
        local x = (love.graphics.getWidth() * 0.1) + (i * 40) + math.sin(time + i) * 20
        local y = (love.graphics.getHeight() * 0.2) + math.cos(time * 0.5 + i) * 30
        love.graphics.circle("fill", x, y, 3)
    end

    -- Title with glow
    local titleFont = love.graphics.newFont(48)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.3, 0.7, 1, 0.3)
    for i = 1, 3 do
        love.graphics.printf("CUBE RUNNER", 0, centerY - 120 + i, love.graphics.getWidth(), "center")
        love.graphics.printf("CUBE RUNNER", 0, centerY - 120 - i, love.graphics.getWidth(), "center")
        love.graphics.printf("CUBE RUNNER", i, centerY - 120, love.graphics.getWidth(), "center")
        love.graphics.printf("CUBE RUNNER", -i, centerY - 120, love.graphics.getWidth(), "center")
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CUBE RUNNER", 0, centerY - 120, love.graphics.getWidth(), "center")

    -- Reset font for other text
    love.graphics.setFont(love.graphics.newFont(14))

    -- Menu options
    for i, option in ipairs(menuOptions) do
        local y = centerY - 20 + (i - 1) * 40

        if i == menuSelection then
            love.graphics.setColor(0.3, 0.7, 1)
            love.graphics.rectangle("fill", centerX - 100, y - 5, 200, 30)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("> " .. option .. " <", 0, y, love.graphics.getWidth(), "center")
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf(option, 0, y, love.graphics.getWidth(), "center")
        end
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Use W/S to navigate, SPACE/Enter to select", 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
end

function drawOptionsMenu()
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PLAYER OPTIONS", 0, centerY - 100, love.graphics.getWidth(), "center")

    for i, option in ipairs(optionsMenu) do
        local y = centerY - 20 + (i - 1) * 40

        if i == optionsSelection then
            love.graphics.setColor(0.3, 0.7, 1)
            love.graphics.rectangle("fill", centerX - 120, y - 5, 240, 30)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("> " .. option .. " <", 0, y, love.graphics.getWidth(), "center")
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf(option, 0, y, love.graphics.getWidth(), "center")
        end
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("W/S, SPACE/Enter to select, ESC to go back", 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
end

function drawCustomizeMenu()
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    local player = playerData[currentPlayer]

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Title
    love.graphics.setColor(player.color[1], player.color[2], player.color[3])
    love.graphics.printf("CUSTOMIZE PLAYER " .. currentPlayer, 0, centerY - 150, love.graphics.getWidth(), "center")

    -- Current player preview
    love.graphics.setColor(player.color[1], player.color[2], player.color[3])
    love.graphics.rectangle("fill", centerX - 15, centerY - 120, 30, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(player.name, 0, centerY - 85, love.graphics.getWidth(), "center")

    -- Customization options
    for i, option in ipairs(customizeOptions) do
        local y = centerY - 20 + (i - 1) * 40
        local displayText = option

        if option == "Name" then
            displayText = "Name: " .. player.name
        elseif option == "Color" then
            displayText = "Color: " .. getColorName(player.color)
        elseif option == "Keybinds" then
            displayText = "Keybinds: " .. getKeybindString(player.keybinds)
        end

        if i == customizeSelection then
            love.graphics.setColor(0.3, 0.7, 1)
            love.graphics.rectangle("fill", centerX - 150, y - 5, 300, 30)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("> " .. displayText .. " <", 0, y, love.graphics.getWidth(), "center")
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf(displayText, 0, y, love.graphics.getWidth(), "center")
        end
    end

    -- Input mode handling
    if inputMode == "name" then
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Enter new name: " .. inputBuffer .. "_", 0, centerY + 120, love.graphics.getWidth(), "center")
        love.graphics.printf("Press ENTER to confirm, ESC to cancel", 0, centerY + 140, love.graphics.getWidth(), "center")
    elseif keybindWaiting ~= "" then
        love.graphics.setColor(1, 1, 0)
        local keybindText = "Press key for " .. keybindWaiting
        if keybindWaiting == "ability" then
            keybindText = "Press key for Class Ability"
        end
        love.graphics.printf(keybindText .. "...", 0, centerY + 120, love.graphics.getWidth(), "center")
        love.graphics.printf("ESC to cancel", 0, centerY + 140, love.graphics.getWidth(), "center")
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("W/S to navigate, SPACE/Enter to edit, ESC to go back", 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
    end
end

function getColorName(color)
    for _, preset in ipairs(colorPresets) do
        if preset.color[1] == color[1] and preset.color[2] == color[2] and preset.color[3] == color[3] then
            return preset.name
        end
    end
    return "Custom"
end

function getKeybindString(keybinds)
    return string.upper(keybinds.up .. keybinds.left .. keybinds.down .. keybinds.right) .. 
           " + " .. string.upper(keybinds.dash) .. 
           " + " .. string.upper(keybinds.ability)
end

function cycleColor(player, direction)
    local currentIndex = 1
    for i, preset in ipairs(colorPresets) do
        if preset.color[1] == player.color[1] and preset.color[2] == player.color[2] and preset.color[3] == player.color[3] then
            currentIndex = i
            break
        end
    end

    if direction == 1 then
        currentIndex = currentIndex + 1
        if currentIndex > #colorPresets then
            currentIndex = 1
        end
    else
        currentIndex = currentIndex - 1
        if currentIndex < 1 then
            currentIndex = #colorPresets
        end
    end

    player.color = {colorPresets[currentIndex].color[1], colorPresets[currentIndex].color[2], colorPresets[currentIndex].color[3]}
end

function drawBeam(player)
    if player.beamActive then
        -- Draw beam
        love.graphics.setLineWidth(12)
        love.graphics.setColor(player.color[1], player.color[2], player.color[3], 0.8)
        love.graphics.line(player.dashStartPos.x, player.dashStartPos.y, player.x, player.y)

        -- Draw beam core (brighter)
        love.graphics.setLineWidth(6)
        love.graphics.setColor(player.color[1], player.color[2], player.color[3], 1)
        love.graphics.line(player.dashStartPos.x, player.dashStartPos.y, player.x, player.y)

        love.graphics.setLineWidth(1) -- Reset line width
    end
end

function drawTrail(player)
    for i, trail in ipairs(player.trail) do
        local alpha = trail.life / trail.maxLife
        love.graphics.setColor(player.color[1], player.color[2], player.color[3], alpha * 0.5)
        love.graphics.rectangle("fill", trail.x - player.size/2, trail.y - player.size/2, player.size, player.size)
    end
end

function drawPlayer(player)
    -- Draw glow (when dashing or invulnerable)
    if player.glowIntensity > 0 or player.invulnerable > 0 then
        local glowAlpha = player.glowIntensity * 0.3
        if player.invulnerable > 0 then
            glowAlpha = math.max(glowAlpha, 0.5 * (1 + math.sin(love.timer.getTime() * 10)))
        end
        love.graphics.setColor(player.color[1], player.color[2], player.color[3], glowAlpha)
        love.graphics.circle("fill", player.x, player.y, player.size + 8)
    end

    -- Draw player cube
    if player.invulnerable > 0 and math.floor(love.timer.getTime() * 8) % 2 == 0 then
        -- Flashing when invulnerable
        love.graphics.setColor(1, 1, 1, 0.5)
    else
        love.graphics.setColor(player.color[1], player.color[2], player.color[3])
    end
    love.graphics.rectangle("fill", player.x - player.size/2, player.y - player.size/2, player.size, player.size)
end

function drawUI()
    love.graphics.setColor(1, 1, 1)

    -- Health bars
    local barWidth = 200
    local barHeight = 20

    -- Player 1
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 15, 20, barWidth, barHeight)
    love.graphics.setColor(player1.color[1], player1.color[2], player1.color[3])
    love.graphics.rectangle("fill", 15, 20, (player1.health / player1.maxHealth) * barWidth, barHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 15, 20, barWidth, barHeight)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(playerData[1].name .. "'s Health: " .. player1.health, 20, 23)

    -- Player 2 health
    local rightX = love.graphics.getWidth() - barWidth - 20
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", rightX, 20, barWidth, barHeight)
    love.graphics.setColor(player2.color[1], player2.color[2], player2.color[3])
    love.graphics.rectangle("fill", rightX, 20, (player2.health / player2.maxHealth) * barWidth, barHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", rightX, 20, barWidth, barHeight)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(playerData[2].name .. "'s Health: " .. player2.health, rightX + 5, 23)

    -- Dash cooldowns
    drawCooldown(player1, 15, 50, playerData[1].name .. "'s Dash")
    drawCooldown(player2, rightX, 50, playerData[2].name .. "'s Dash")

    -- Ability cooldowns and effects
    drawAbilityUI(player1, 15, 80, playerData[1])
    drawAbilityUI(player2, rightX, 80, playerData[2])
end

function drawAbilityUI(player, x, y, playerData)
    local barWidth = 100
    local barHeight = 10

    -- Draw class name
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(playerData.class.name, x, y - 15)

    -- Draw ability name
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(playerData.class.ability.name, x, y + 5)

    -- Draw ability uses
    if player.abilityActive or player.doubleDashAvailable then
        local usesText = "Uses: " .. player.abilityUses .. "/" .. player.abilityMaxUses
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print(usesText, x, y + 20)
    end

    -- Draw cooldown
    if player.abilityCooldown > 0 then
        local cooldownPercent = player.abilityCooldown / 10 -- Max cooldown is 10 seconds
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.rectangle("fill", x, y + 35, barWidth * cooldownPercent, barHeight)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("line", x, y + 35, barWidth, barHeight)
    else
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.rectangle("fill", x, y + 35, barWidth, barHeight)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("line", x, y + 35, barWidth, barHeight)
    end

    -- Draw active effects
    if player.abilityActive then
        local effectText = ""
        if playerData.class.name == "Warrior" then
            effectText = "Power Dash Active!"
        elseif playerData.class.name == "Tank" then
            effectText = "Shield Active!"
        end
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(effectText, x, y + 50)
    end

    if player.doubleDashAvailable then
        love.graphics.setColor(0, 1, 1)
        love.graphics.print("Double Dash Ready!", x, y + 50)
    end
end

function drawCooldown(player, x, y, label)
    local barWidth = 100
    local barHeight = 10

    if player.dashCooldown > 0 then
        local cooldownPercent = player.dashCooldown / player.dashCooldownMax
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.rectangle("fill", x, y, barWidth * cooldownPercent, barHeight)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("line", x, y, barWidth, barHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(label .. " Cooldown", x, y + 15)
    else
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.rectangle("fill", x, y, barWidth, barHeight)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("line", x, y, barWidth, barHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(label .. " Ready!", x, y + 15)
    end
end

function drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw win animation
    drawWinAnimation()

    -- Draw restart text with pulsing effect
    local pulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
    love.graphics.setColor(1, 1, 1, pulse)
    local font = love.graphics.getFont()
    local restartText = "Press R to restart or ESC to quit"
    local restartWidth = font:getWidth(restartText)
    love.graphics.print(restartText, love.graphics.getWidth()/2 - restartWidth/2, love.graphics.getHeight()/2 + 50)
end

function startGame()
    gameState = "playing"

    -- Apply selected game mode
    gameMode = gameMode -- This will be set by mode selection

    -- Apply custom colors and names (friction will be set by initializePlayer)
    initializePlayer(player1, 200, 300, playerData[1].color, playerData[1].colorName)
    initializePlayer(player2, 600, 300, playerData[2].color, playerData[2].colorName)

    particles = {}
    screenShake = { intensity = 0, duration = 0 }
    winner = ""
end

function love.keypressed(key)
    if gameState == "menu" then
        if showingControls then
            if key == "escape" or key == "return" then
                showingControls = false
            end
        elseif showingModeSelect then
            if key == "w" then
                modeSelection = modeSelection - 1
                if modeSelection < 1 then modeSelection = #modeOptions end
            elseif key == "s" then
                modeSelection = modeSelection + 1
                if modeSelection > #modeOptions then modeSelection = 1 end
            elseif key == "space" or key == "return" then
                if modeSelection == 1 then -- Regular
                    gameMode = "regular"
                    gameState = "class_select"
                    classSelectPlayer = 1
                    classSelection = 1
                elseif modeSelection == 2 then -- Icey
                    gameMode = "icey"
                    gameState = "class_select"
                    classSelectPlayer = 1
                    classSelection = 1
                elseif modeSelection == 3 then -- Back
                    showingModeSelect = false
                    modeSelection = 1
                end
            elseif key == "escape" then
                showingModeSelect = false
                modeSelection = 1
            end
        else
            if key == "w" then
                menuSelection = menuSelection - 1
                if menuSelection < 1 then menuSelection = #menuOptions end
            elseif key == "s" then
                menuSelection = menuSelection + 1
                if menuSelection > #menuOptions then menuSelection = 1 end
            elseif key == "space" or key == "return" then
                if menuSelection == 1 then -- Start Game
                    showingModeSelect = true
                    modeSelection = 1
                elseif menuSelection == 2 then -- Player Options
                    gameState = "options"
                    optionsSelection = 1
                elseif menuSelection == 3 then -- Controls
                    showingControls = true
                elseif menuSelection == 4 then -- Quit
                    love.event.quit()
                end
            elseif key == "escape" then
                love.event.quit()
            end
        end
    elseif gameState == "options" then
        if key == "w" then
            optionsSelection = optionsSelection - 1
            if optionsSelection < 1 then optionsSelection = #optionsMenu end
        elseif key == "s" then
            optionsSelection = optionsSelection + 1
            if optionsSelection > #optionsMenu then optionsSelection = 1 end
        elseif key == "space" or key == "return" then
            if optionsSelection == 1 then -- Customize Player 1
                gameState = "customize_p1"
                currentPlayer = 1
                customizeSelection = 1
            elseif optionsSelection == 2 then -- Customize Player 2
                gameState = "customize_p2"
                currentPlayer = 2
                customizeSelection = 1
            elseif optionsSelection == 3 then -- Back
                gameState = "menu"
            end
        elseif key == "escape" then
            gameState = "menu"
        end
    elseif gameState == "customize_p1" or gameState == "customize_p2" then
        local player = playerData[currentPlayer]

        if inputMode == "name" then
            if key == "space" then
                if inputBuffer ~= "" then
                    player.name = inputBuffer
                end
                inputMode = ""
                inputBuffer = ""
            elseif key == "escape" then
                inputMode = ""
                inputBuffer = ""
            elseif key == "backspace" then
                inputBuffer = inputBuffer:sub(1, -2)
            end
        elseif keybindWaiting ~= "" then
            if key == "escape" then
                keybindWaiting = ""
            else
                -- List of keys that should not be allowed as keybinds
                local invalidKeys = {
                    "escape", "return", "backspace", "tab", "capslock",
                    "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt",
                    "lgui", "rgui", "menu", "printscreen", "scrolllock", "pause",
                    "insert", "home", "pageup", "delete", "end", "pagedown",
                    "numlock", "kp0", "kp1", "kp2", "kp3", "kp4", "kp5", "kp6", "kp7", "kp8", "kp9",
                    "kp.", "kp/", "kp*", "kp-", "kp+", "kpenter", "kp="
                }
                
                local isInvalid = false
                for _, invalidKey in ipairs(invalidKeys) do
                    if key == invalidKey then
                        isInvalid = true
                        break
                    end
                end
                
                if not isInvalid then
                    -- Check if this key is bound to a different action
                    local oldAction = nil
                    for action, bind in pairs(player.keybinds) do
                        if bind == key and action ~= keybindWaiting then
                            oldAction = action
                            break
                        end
                    end
                    
                    -- If the key is bound to a different action, swap the bindings
                    if oldAction then
                        local temp = player.keybinds[oldAction]
                        player.keybinds[oldAction] = player.keybinds[keybindWaiting]
                        player.keybinds[keybindWaiting] = key
                    else
                        player.keybinds[keybindWaiting] = key
                    end
                    
                    handleKeybindSequence()
                end
            end
        else
            if key == "w" then
                customizeSelection = customizeSelection - 1
                if customizeSelection < 1 then customizeSelection = #customizeOptions end
            elseif key == "s" then
                customizeSelection = customizeSelection + 1
                if customizeSelection > #customizeOptions then customizeSelection = 1 end
            elseif key == "space" or key == "return" then
                if customizeSelection == 1 then -- Name
                    inputMode = "name"
                    inputBuffer = player.name
                elseif customizeSelection == 2 then -- Color
                    cycleColor(player, 1)
                elseif customizeSelection == 3 then -- Keybinds
                    keybindWaiting = "up"
                elseif customizeSelection == 4 then -- Back
                    gameState = "options"
                end
            elseif key == "a" and customizeSelection == 2 then
                cycleColor(player, -1)
            elseif key == "d" and customizeSelection == 2 then
                cycleColor(player, 1)
            elseif key == "escape" then
                gameState = "options"
            end
        end
    elseif gameState == "class_select" then
        if key == "w" then
            classSelection = classSelection - 1
            if classSelection < 1 then classSelection = #classes end
        elseif key == "s" then
            classSelection = classSelection + 1
            if classSelection > #classes then classSelection = 1 end
        elseif key == "space" or key == "return" then
            -- Assign selected class to current player
            playerData[classSelectPlayer].class = classes[classSelection]
            playerData[classSelectPlayer].ability = classes[classSelection].ability
            
            if classSelectPlayer == 1 then
                -- Move to player 2's selection
                classSelectPlayer = 2
                classSelection = 1
            else
                -- Both players have selected, start the game
                startGame()
            end
        elseif key == "escape" then
            -- Go back to mode selection
            gameState = "menu"
            showingModeSelect = true
        end
    elseif gameState == "gameover" then
        if key == "escape" then
            initializeMenu()
            gameState = "menu"
            winAnimation.active = false
        elseif key == "r" then
            startGame()
        end
    end
end

function love.textinput(text)
    if inputMode == "name" and #inputBuffer < 20 then
        inputBuffer = inputBuffer .. text
    end
end

function handleKeybindSequence()
    local sequence = {"up", "down", "left", "right", "dash", "ability"}
    local currentIndex = 1

    for i, bind in ipairs(sequence) do
        if keybindWaiting == bind then
            currentIndex = i
            break
        end
    end

    if currentIndex < #sequence then
        keybindWaiting = sequence[currentIndex + 1]
    else
        keybindWaiting = ""
    end
end

function createVictoryShader()
    local vertexCode = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return transform_projection * vertex_position;
        }
    ]]

    local fragmentCode = [[
        uniform float time;
        uniform vec2 resolution;
        uniform vec3 winnerColor;
        uniform float intensity;

        // Hash function for pseudo-random values
        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
        }

        // Noise function
        float noise(vec2 p) {
            vec2 i = floor(p);
            vec2 f = fract(p);
            float a = hash(i);
            float b = hash(i + vec2(1.0, 0.0));
            float c = hash(i + vec2(0.0, 1.0));
            float d = hash(i + vec2(1.0, 1.0));
            vec2 u = f * f * (3.0 - 2.0 * f);
            return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }

        // Fractal noise
        float fbm(vec2 p) {
            float value = 0.0;
            float amplitude = 0.5;
            for (int i = 0; i < 6; i++) {
                value += amplitude * noise(p);
                p *= 2.0;
                amplitude *= 0.5;
            }
            return value;
        }

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 uv = screen_coords / resolution;
            vec2 center = vec2(0.5, 0.5);
            
            // Create moving UV coordinates
            vec2 movingUV = uv + vec2(sin(time * 0.3), cos(time * 0.2)) * 0.1;
            
            // Multiple layers of animated patterns
            float layer1 = fbm(movingUV * 3.0 + time * 0.5);
            float layer2 = fbm(movingUV * 6.0 - time * 0.3);
            float layer3 = fbm(movingUV * 12.0 + time * 0.8);
            
            // Swirling pattern
            float angle = atan(uv.y - center.y, uv.x - center.x);
            float radius = length(uv - center);
            float spiral = sin(angle * 4.0 + radius * 12.0 - time * 2.0) * 0.5 + 0.5;
            
            // Combine patterns
            float combined = layer1 * 0.4 + layer2 * 0.3 + layer3 * 0.2 + spiral * 0.3;
            
            // Create color variations
            vec3 baseColor = winnerColor;
            vec3 color1 = baseColor * (0.8 + sin(time * 0.5) * 0.2);
            vec3 color2 = baseColor * (0.6 + cos(time * 0.3) * 0.2);
            
            // Mix colors based on the combined pattern
            vec3 finalColor = mix(color1, color2, combined);
            
            // Add brightness variations
            finalColor *= (0.8 + combined * 0.4);
            
            // Add intensity-based glow
            finalColor *= (1.0 + intensity * 0.5);
            
            // Add subtle pulsing
            float pulse = (sin(time * 1.2) + sin(time * 1.7) + sin(time * 2.1)) * 0.1 + 0.9;
            finalColor *= pulse;
            
            return vec4(finalColor, 1.0);
        }
    ]]

    winAnimation.shader = love.graphics.newShader(fragmentCode, vertexCode)
end

function createWinParticles(x, y, color)
    -- Main explosion particles
    for i = 1, 50 do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(100, 300)
        local size = love.math.random(3, 8)
        local life = love.math.random(0.5, 1.5)
        
        table.insert(winAnimation.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = size,
            color = color,
            life = life,
            maxLife = life,
            rotation = love.math.random() * math.pi * 2,
            rotationSpeed = (love.math.random() - 0.5) * 10,
            type = "square"
        })
    end

    -- Add some circular particles
    for i = 1, 30 do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(50, 200)
        local size = love.math.random(2, 6)
        local life = love.math.random(0.8, 2.0)
        
        table.insert(winAnimation.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = size,
            color = color,
            life = life,
            maxLife = life,
            type = "circle"
        })
    end

    -- Add victory beams
    for i = 1, 8 do
        local angle = (i - 1) * (math.pi / 4)
        table.insert(winAnimation.victoryBeams, {
            x = x,
            y = y,
            angle = angle,
            length = 0,
            maxLength = love.math.random(100, 200),
            width = love.math.random(5, 15),
            life = 1.5,
            maxLife = 1.5,
            color = color
        })
    end

    -- Add sparkles
    for i = 1, 20 do
        table.insert(winAnimation.sparkles, {
            x = love.math.random(0, love.graphics.getWidth()),
            y = love.math.random(0, love.graphics.getHeight()),
            size = love.math.random(2, 4),
            life = love.math.random(0.5, 1.0),
            maxLife = 1.0,
            color = color
        })
    end
end

function updateWinAnimation(dt)
    if not winAnimation.active then return end
    
    winAnimation.elapsed = winAnimation.elapsed + dt
    local progress = math.sin(winAnimation.elapsed * 0.5) * 0.5 + 0.5 -- Oscillating progress
    
    -- Update scale and rotation
    winAnimation.scale = 1 + math.sin(winAnimation.elapsed * 2) * 0.1
    winAnimation.rotation = winAnimation.elapsed * 0.5
    
    -- Update text alpha and glow
    winAnimation.textAlpha = 1
    winAnimation.textGlow = math.sin(winAnimation.elapsed * 2) * 0.5 + 0.5
    
    -- Update camera offset (subtle movement)
    winAnimation.cameraOffset.x = math.sin(winAnimation.elapsed * 2) * 5
    winAnimation.cameraOffset.y = math.cos(winAnimation.elapsed * 2) * 5
    
    -- Update particles
    for i = #winAnimation.particles, 1, -1 do
        local p = winAnimation.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = p.vx * 0.98
        p.vy = p.vy * 0.98
        p.life = p.life - dt
        if p.rotationSpeed then
            p.rotation = p.rotation + p.rotationSpeed * dt
        end
        
        if p.life <= 0 then
            -- Instead of removing, reset the particle
            p.x = love.graphics.getWidth()/2
            p.y = love.graphics.getHeight()/2
            local angle = love.math.random() * math.pi * 2
            local speed = love.math.random(100, 300)
            p.vx = math.cos(angle) * speed
            p.vy = math.sin(angle) * speed
            p.life = p.maxLife
        end
    end
    
    -- Update victory beams
    for i = #winAnimation.victoryBeams, 1, -1 do
        local beam = winAnimation.victoryBeams[i]
        beam.length = math.min(beam.maxLength, beam.length + 200 * dt)
        beam.life = beam.life - dt
        
        if beam.life <= 0 then
            -- Reset beam instead of removing
            beam.length = 0
            beam.life = beam.maxLife
        end
    end
    
    -- Update sparkles
    for i = #winAnimation.sparkles, 1, -1 do
        local sparkle = winAnimation.sparkles[i]
        sparkle.life = sparkle.life - dt
        sparkle.size = sparkle.size * 0.98
        
        if sparkle.life <= 0 then
            -- Reset sparkle instead of removing
            sparkle.x = love.math.random(0, love.graphics.getWidth())
            sparkle.y = love.math.random(0, love.graphics.getHeight())
            sparkle.size = love.math.random(2, 4)
            sparkle.life = sparkle.maxLife
        end
    end
end

function drawWinAnimation()
    if not winAnimation.active then return end
    
    -- Draw shader background
    if winAnimation.shader then
        winAnimation.shader:send("time", winAnimation.elapsed)
        winAnimation.shader:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})
        winAnimation.shader:send("winnerColor", {winAnimation.particles[1].color[1], 
                                               winAnimation.particles[1].color[2], 
                                               winAnimation.particles[1].color[3]})
        winAnimation.shader:send("intensity", math.sin(winAnimation.elapsed) * 0.5 + 0.5)
        
        love.graphics.setShader(winAnimation.shader)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader()
    end
    
    -- Draw victory beams
    for _, beam in ipairs(winAnimation.victoryBeams) do
        local alpha = beam.life / beam.maxLife
        love.graphics.setColor(beam.color[1], beam.color[2], beam.color[3], alpha * 0.7)
        love.graphics.push()
        love.graphics.translate(beam.x, beam.y)
        love.graphics.rotate(beam.angle)
        love.graphics.rectangle("fill", 0, -beam.width/2, beam.length, beam.width)
        love.graphics.pop()
    end
    
    -- Draw particles
    for _, p in ipairs(winAnimation.particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        if p.rotation then
            love.graphics.rotate(p.rotation)
        end
        if p.type == "circle" then
            love.graphics.circle("fill", 0, 0, p.size/2)
        else
            love.graphics.rectangle("fill", -p.size/2, -p.size/2, p.size, p.size)
        end
        love.graphics.pop()
    end
    
    -- Draw sparkles
    for _, sparkle in ipairs(winAnimation.sparkles) do
        local alpha = sparkle.life / sparkle.maxLife
        love.graphics.setColor(sparkle.color[1], sparkle.color[2], sparkle.color[3], alpha)
        love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
    end
    
    -- Draw winner text with enhanced effects
    local font = love.graphics.getFont()
    local text = winner
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    
    -- Draw text glow
    love.graphics.setColor(1, 1, 1, winAnimation.textGlow * 0.7)
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2 + winAnimation.cameraOffset.x, 
                          love.graphics.getHeight()/2 + winAnimation.cameraOffset.y)
    love.graphics.scale(winAnimation.scale * 1.1) -- Slightly larger glow
    love.graphics.rotate(winAnimation.rotation * 0.1)
    love.graphics.print(text, -textWidth/2, -textHeight/2)
    love.graphics.pop()
    
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2 + winAnimation.cameraOffset.x, 
                          love.graphics.getHeight()/2 + winAnimation.cameraOffset.y)
    love.graphics.scale(winAnimation.scale)
    love.graphics.rotate(winAnimation.rotation * 0.1)
    love.graphics.print(text, -textWidth/2, -textHeight/2)
    love.graphics.pop()
end

function drawClassSelect()
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2

    drawBackground()

    -- Title with glow effect
    local titleFont = love.graphics.newFont(36)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 0.3)
    for i = 1, 3 do
        love.graphics.printf("SELECT CLASS - PLAYER " .. classSelectPlayer, 0, centerY - 280 + i, love.graphics.getWidth(), "center")
        love.graphics.printf("SELECT CLASS - PLAYER " .. classSelectPlayer, 0, centerY - 280 - i, love.graphics.getWidth(), "center")
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECT CLASS - PLAYER " .. classSelectPlayer, 0, centerY - 280, love.graphics.getWidth(), "center")

    -- Reset font for class options
    love.graphics.setFont(love.graphics.newFont(14))

    -- Draw class options in a grid layout
    local classWidth = 280
    local classHeight = 180
    local padding = 20
    local startX = centerX - (classWidth + padding)
    local startY = centerY - 200  -- Moved up from -80 to -200

    for i, class in ipairs(classes) do
        local row = math.floor((i-1) / 2)
        local col = (i-1) % 2
        local x = startX + (classWidth + padding) * col
        local y = startY + (classHeight + padding) * row

        -- Draw class card background
        if i == classSelection then
            -- Selected class highlight
            love.graphics.setColor(class.color[1], class.color[2], class.color[3], 0.3)
            love.graphics.rectangle("fill", x - 10, y - 10, classWidth + 20, classHeight + 20, 10, 10)
            love.graphics.setColor(class.color[1], class.color[2], class.color[3], 0.8)
            love.graphics.rectangle("line", x - 10, y - 10, classWidth + 20, classHeight + 20, 10, 10)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", x, y, classWidth, classHeight, 10, 10)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("line", x, y, classWidth, classHeight, 10, 10)
        end

        -- Class name with color
        love.graphics.setColor(class.color[1], class.color[2], class.color[3])
        love.graphics.printf(class.name, x, y + 20, classWidth, "center")

        -- Class description
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf(class.description, x + 20, y + 50, classWidth - 40, "center")

        -- Ability info with icon
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Ability: " .. class.ability.name, x + 20, y + 100, classWidth - 40, "center")
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf(class.ability.description, x + 20, y + 120, classWidth - 40, "center")

        -- Keybind info
        love.graphics.setColor(0.5, 0.5, 0.5)
        local keybindText = "Press " .. string.upper(playerData[classSelectPlayer].keybinds.ability) .. " to use ability"
        love.graphics.printf(keybindText, x + 20, y + 160, classWidth - 40, "center")
    end

    -- Instructions with better visibility
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("W/S to navigate, SPACE/Enter to select, ESC to go back", 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
end

function activateAbility(player)
    local playerIndex = (player == player1) and 1 or 2
    local class = playerData[playerIndex].class

    if class.name == "Warrior" then
        -- Power Dash: Increased dash damage for next 2 dashes
        player.abilityActive = true
        player.abilityUses = 2
        player.abilityMaxUses = 2
        player.abilityCooldown = 8.0
    elseif class.name == "Mage" then
        -- Teleport: Teleport to the other player
        local targetPlayer = (player == player1) and player2 or player1
        
        -- Calculate direction to target player
        local dx = targetPlayer.x - player.x
        local dy = targetPlayer.y - player.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- Normalize direction
        if distance > 0 then
            dx = dx / distance
            dy = dy / distance
        end
        
        -- Calculate target position (slightly offset from target player)
        local targetX = targetPlayer.x - dx * 50  -- Offset by 50 pixels away from target
        local targetY = targetPlayer.y - dy * 50
        
        -- Ensure target is within screen bounds
        local borderSize = 10
        targetX = math.max(player.size/2 + borderSize, math.min(love.graphics.getWidth() - player.size/2 - borderSize, targetX))
        targetY = math.max(player.size/2 + borderSize, math.min(love.graphics.getHeight() - player.size/2 - borderSize, targetY))
        
        -- Check for obstacle collisions
        if not checkObstacleCollision(targetX, targetY, player.size) then
            -- Add teleport start particles
            for i = 1, 10 do
                table.insert(particles, {
                    x = player.x + love.math.random(-20, 20),
                    y = player.y + love.math.random(-20, 20),
                    vx = love.math.random(-100, 100),
                    vy = love.math.random(-100, 100),
                    life = 0.5,
                    maxLife = 0.5,
                    size = love.math.random(2, 4),
                    color = player.color
                })
            end
            
            -- Teleport
            player.x = targetX
            player.y = targetY
            player.abilityCooldown = 4.0
            
            -- Add teleport end particles
            for i = 1, 10 do
                table.insert(particles, {
                    x = player.x + love.math.random(-20, 20),
                    y = player.y + love.math.random(-20, 20),
                    vx = love.math.random(-100, 100),
                    vy = love.math.random(-100, 100),
                    life = 0.5,
                    maxLife = 0.5,
                    size = love.math.random(2, 4),
                    color = player.color
                })
            end
        end
    elseif class.name == "Rogue" then
        -- Double Dash: Can dash twice in quick succession
        player.doubleDashAvailable = true
        player.abilityUses = 2
        player.abilityMaxUses = 2
        player.abilityCooldown = 6.0
    elseif class.name == "Tank" then
        -- Shield: Damage reduction for next 3 hits
        player.shieldActive = true
        player.abilityActive = true
        player.abilityUses = 3
        player.abilityMaxUses = 3
        player.abilityCooldown = 7.0
    end
end

function deactivateAbility(player)
    if player.abilityUses <= 0 then
        player.abilityActive = false
        player.shieldActive = false
        player.doubleDashAvailable = false
    end
end
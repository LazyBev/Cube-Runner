local ClassSystem = {}

-- Load audio manager
local AudioManager = require("systems.audio_manager")

-- Animation variables
local hoverEffect = 0
local selectionEffect = 0
local titleScale = 1
local titleRotation = 0

local classes = {
    {
        name = "Void Knight",
        description = "A mysterious warrior wielding void energy. High health and devastating dash attacks, but slower movement.",
        stats = {
            health = 180,
            damage = 25,
            dashDamage = 80,
            speed = 220,
            dashSpeed = 800,
            dashCooldown = 1.2,
            special = "Void Surge: Dash leaves a trail of void energy that damages enemies"
        },
        color = {0.4, 0.1, 0.5},
        dashColor = {0.6, 0.2, 0.8},
        icon = "VK"
    },
    {
        name = "Storm Blade",
        description = "A lightning-fast warrior harnessing the power of storms. Incredible speed and chain dash capabilities.",
        stats = {
            health = 90,
            damage = 15,
            dashDamage = 40,
            speed = 400,
            dashSpeed = 1000,
            dashCooldown = 0.8,
            special = "Storm Chain: Successive dashes deal increasing damage"
        },
        color = {0.2, 0.7, 0.9},
        dashColor = {0.4, 0.9, 1.0},
        icon = "SB"
    },
    {
        name = "Crystal Sage",
        description = "A master of crystalline magic. Balanced stats with powerful area damage on dash.",
        stats = {
            health = 120,
            damage = 30,
            dashDamage = 60,
            speed = 280,
            dashSpeed = 750,
            dashCooldown = 1.0,
            special = "Crystal Burst: Dash creates crystal shards that damage nearby enemies"
        },
        color = {0.8, 0.8, 0.2},
        dashColor = {1.0, 1.0, 0.4},
        icon = "CS"
    },
    {
        name = "Inferno Berserker",
        description = "A raging warrior wreathed in flames. High damage and burning dash attacks.",
        stats = {
            health = 150,
            damage = 35,
            dashDamage = 70,
            speed = 250,
            dashSpeed = 850,
            dashCooldown = 1.1,
            special = "Burning Trail: Dash leaves a trail of fire that damages enemies over time"
        },
        color = {0.8, 0.3, 0.1},
        dashColor = {1.0, 0.5, 0.2},
        icon = "IB"
    }
}

local selectedClass = 1
local hoveredClass = 1
local keyRepeatTimer = 0
local keyRepeatDelay = 0.15
local keyRepeatRate = 0.05

function ClassSystem.init()
    selectedClass = 1
    hoveredClass = 1
    hoverEffect = 0
    selectionEffect = 0
    titleScale = 1
    titleRotation = 0
end

function ClassSystem.update(dt)
    -- Update animations
    hoverEffect = math.max(0, hoverEffect - dt * 2)
    selectionEffect = math.max(0, selectionEffect - dt * 3)
    titleScale = 1 + math.sin(love.timer.getTime() * 2) * 0.05
    titleRotation = math.sin(love.timer.getTime()) * 0.1
    
    -- Handle key repeat
    if keyRepeatTimer > 0 then
        keyRepeatTimer = keyRepeatTimer - dt
    end
    
    -- Check for held keys
    if love.keyboard.isDown("up", "w") then
        if keyRepeatTimer <= 0 then
            if hoveredClass > 2 then
                hoveredClass = hoveredClass - 2
                hoverEffect = 1
                AudioManager.playSound("menuMove")
                keyRepeatTimer = keyRepeatDelay
            end
        end
    elseif love.keyboard.isDown("down", "s") then
        if keyRepeatTimer <= 0 then
            if hoveredClass <= 2 then
                hoveredClass = hoveredClass + 2
                hoverEffect = 1
                AudioManager.playSound("menuMove")
                keyRepeatTimer = keyRepeatDelay
            end
        end
    elseif love.keyboard.isDown("left", "a") then
        if keyRepeatTimer <= 0 then
            hoveredClass = hoveredClass - 1
            if hoveredClass < 1 then hoveredClass = #classes end
            hoverEffect = 1
            AudioManager.playSound("menuMove")
            keyRepeatTimer = keyRepeatDelay
        end
    elseif love.keyboard.isDown("right", "d") then
        if keyRepeatTimer <= 0 then
            hoveredClass = hoveredClass + 1
            if hoveredClass > #classes then hoveredClass = 1 end
            hoverEffect = 1
            AudioManager.playSound("menuMove")
            keyRepeatTimer = keyRepeatDelay
        end
    end
end

function ClassSystem.draw()
    -- Draw background with gradient
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    for i = 0, height do
        local t = i / height
        local r, g, b = 0.1 + t * 0.1, 0.1 + t * 0.1, 0.15 + t * 0.1
        love.graphics.setColor(r, g, b)
        love.graphics.line(0, i, width, i)
    end
    
    -- Draw animated title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(44))
    love.graphics.push()
    love.graphics.translate(width/2, 44)
    love.graphics.scale(titleScale, titleScale)
    love.graphics.rotate(titleRotation)
    love.graphics.printf("Choose Your Champion", -width/2, 0, width, "center")
    love.graphics.pop()
    
    -- Calculate grid layout (medium cards)
    local cardWidth = 410
    local cardHeight = 210
    local padding = 38
    local startX = (width - (cardWidth * 2 + padding)) / 2
    local startY = 180
    
    -- Draw class options in 2x2 grid
    for i, class in ipairs(classes) do
        -- Calculate grid position
        local row = math.floor((i - 1) / 2)
        local col = (i - 1) % 2
        local x = startX + col * (cardWidth + padding)
        local y = startY + row * (cardHeight + padding)
        
        local isHovered = i == hoveredClass
        local isSelected = i == selectedClass
        
        -- Calculate hover and selection effects
        local hover = isHovered and hoverEffect or 0
        local select = isSelected and selectionEffect or 0
        local glow = math.max(hover, select)
        
        -- Draw selection highlight with glow
        if glow > 0 then
            local radius = 20
            -- Draw outer glow just slightly larger and centered
            love.graphics.setColor(class.color[1], class.color[2], class.color[3], glow * 0.25)
            love.graphics.rectangle("fill", x - 4, y - 4, cardWidth + 8, cardHeight + 8, radius + 8, radius + 8)
            -- Draw border exactly matching the button
            love.graphics.setColor(class.color[1], class.color[2], class.color[3], glow * 0.8)
            love.graphics.setLineWidth(2.5)
            love.graphics.rectangle("line", x, y, cardWidth, cardHeight, radius, radius)
            love.graphics.setLineWidth(1)
        end
        -- Draw class card background
        love.graphics.setColor(0.15, 0.15, 0.15, 0.93)
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 20, 20)
        -- Draw hover cursor
        if isHovered then
            love.graphics.setColor(class.color[1], class.color[2], class.color[3], 1)
            love.graphics.setFont(love.graphics.newFont(18))
            love.graphics.printf(">", x - 26, y + cardHeight/2 - 10, 22, "center")
            love.graphics.printf("<", x + cardWidth, y + cardHeight/2 - 10, 22, "center")
        end
        -- Draw class icon
        love.graphics.setColor(class.color)
        love.graphics.setFont(love.graphics.newFont(28))
        love.graphics.printf(class.icon, x + 20, y + 7, 40, "center")
        -- Draw class name with inverted highlight logic
        if isHovered then
            love.graphics.setColor(class.color)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.setFont(love.graphics.newFont(19))
        love.graphics.printf(class.name, x + 70, y + 12, cardWidth - 80, "left")
        -- Draw description (medium, word wrap)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(class.description, x + 18, y + 38, cardWidth - 36, "left")
        -- Draw special ability (medium, word wrap, more space below description)
        love.graphics.setColor(class.dashColor)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf("Special: " .. class.stats.special, x + 18, y + 70, cardWidth - 36, "left")
        -- Draw stats in two columns, medium font, more space below special
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(love.graphics.newFont(12))
        local statsLeft = string.format(
            "Health: %d\nDamage: %d\nDash Damage: %d",
            class.stats.health,
            class.stats.damage,
            class.stats.dashDamage
        )
        local statsRight = string.format(
            "Speed: %d\nDash Speed: %d\nDash Cooldown: %.1fs",
            class.stats.speed,
            class.stats.dashSpeed,
            class.stats.dashCooldown
        )
        love.graphics.printf(statsLeft, x + 18, y + 108, (cardWidth - 36) / 2, "left")
        love.graphics.printf(statsRight, x + cardWidth/2, y + 108, (cardWidth - 36) / 2, "left")
    end
    -- Draw instructions with keyboard controls
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(15))
    love.graphics.printf("WASD/ARROWS: Navigate  |  ENTER: Select  |  ESC: Back", 0, height - 40, width, "center")
end

function ClassSystem.handleInput(key)
    if key == "up" or key == "w" then
        if hoveredClass > 2 then
            hoveredClass = hoveredClass - 2
            hoverEffect = 1
            AudioManager.playSound("menuMove")
            keyRepeatTimer = keyRepeatDelay
        end
    elseif key == "down" or key == "s" then
        if hoveredClass <= 2 then
            hoveredClass = hoveredClass + 2
            hoverEffect = 1
            AudioManager.playSound("menuMove")
            keyRepeatTimer = keyRepeatDelay
        end
    elseif key == "left" or key == "a" then
        hoveredClass = hoveredClass - 1
        if hoveredClass < 1 then hoveredClass = #classes end
        hoverEffect = 1
        AudioManager.playSound("menuMove")
        keyRepeatTimer = keyRepeatDelay
    elseif key == "right" or key == "d" then
        hoveredClass = hoveredClass + 1
        if hoveredClass > #classes then hoveredClass = 1 end
        hoverEffect = 1
        AudioManager.playSound("menuMove")
        keyRepeatTimer = keyRepeatDelay
    elseif key == "return" then
        selectedClass = hoveredClass
        selectionEffect = 1
        ClassSystem.selectClass(selectedClass)
    elseif key == "escape" or key == "backspace" then
        gameState.currentState = states.MENU
        AudioManager.playMusic("menu")
    end
end

function ClassSystem.handleClick(x, y, button)
    -- Calculate grid layout
    local width = love.graphics.getWidth()
    local cardWidth = 500
    local cardHeight = 200
    local padding = 50
    local startX = (width - (cardWidth * 2 + padding)) / 2
    local startY = 150
    
    -- Check if click is within class selection area
    for i, _ in ipairs(classes) do
        local row = math.floor((i - 1) / 2)
        local col = (i - 1) % 2
        local classX = startX + col * (cardWidth + padding)
        local classY = startY + row * (cardHeight + padding)
        
        if x >= classX and x <= classX + cardWidth and
           y >= classY and y <= classY + cardHeight then
            hoveredClass = i
            if button == 1 then -- Left click
                selectedClass = i
                selectionEffect = 1
                ClassSystem.selectClass(i)
            end
            break
        end
    end
end

function ClassSystem.selectClass(index)
    local Player = require("entities.player")
    local selectedClassData = classes[index]
    gameState.player = Player.new(selectedClassData.name:upper())
    AudioManager.playSound("ability")
    gameState.currentState = states.GAME
    WaveManager.spawnWave(1, gameState.enemies)
end

function ClassSystem.getSelectedClass()
    return classes[hoveredClass]
end

function ClassSystem.getClassData(classType)
    for _, class in ipairs(classes) do
        if class.name:upper():gsub(" ", "_") == classType then
            return class
        end
    end
    return nil
end

return ClassSystem 
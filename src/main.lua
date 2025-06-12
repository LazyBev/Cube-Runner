-- Cube Runner

-- Import modules
local Player = require('entities.player')
local Enemy = require('entities.enemy')
local Boss = require('entities.boss')
local GameState = require('states.gameState')
local Collision = require('utils.collision')
local ParticleSystem = require('utils.particles')

-- Game objects
local player
local gameState
local sounds
local particles

-- Visual polish
local shake = {x = 0, y = 0, t = 0}
local bgTime = 0
local font
local fontLarge
local fontMedium
local fontSmall
local fontTiny

-- Game state
local currentState = 'menu' -- 'menu', 'options', 'game', 'changeControls'

local menuButtons = {
    { text = 'Play', action = function() currentState = 'game' end },
    { text = 'Options', action = function() currentState = 'options' end },
    { text = 'Exit', action = function() love.event.quit() end }
}
local optionsButtons = {
    { text = 'Change Controls', action = function() currentState = 'changeControls' end },
    { text = 'Back', action = function() currentState = 'menu' end }
}
local selectedButton = 1
local controls = {
    left = 'left',
    right = 'right',
    up = 'up',
    down = 'down',
    dash = 'space'
}
local changingControl = nil
local controlOptions = {
    { name = 'Left', key = 'left' },
    { name = 'Right', key = 'right' },
    { name = 'Up', key = 'up' },
    { name = 'Down', key = 'down' },
    { name = 'Dash', key = 'dash' }
}

-- Initialize game
function love.load()
    love.window.setTitle("Cube Runner")
    love.window.setMode(800, 600)
    love.graphics.setBackgroundColor(0.3, 0.28, 0.25) -- Exact brownish-grey ground color from Brotato image
    
    -- Load font for UI (keeping user's chosen font)
    font = love.graphics.newFont('assets/fonts/ka1.ttf', 24) 
    -- Additional fonts for different sizes
    fontLarge = love.graphics.newFont('assets/fonts/ka1.ttf', 60)
    fontMedium = love.graphics.newFont('assets/fonts/ka1.ttf', 30)
    fontSmall = love.graphics.newFont('assets/fonts/ka1.ttf', 20)
    fontTiny = love.graphics.newFont('assets/fonts/ka1.ttf', 16)
    
    -- Load sounds (keeping user's chosen bossSpawn extension)
    sounds = {
        dash = love.audio.newSource('assets/sounds/dash.mp3', 'static'),
        hit = love.audio.newSource('assets/sounds/hit.mp3', 'static'),
        bossSpawn = love.audio.newSource('assets/sounds/boss_spawn.wav', 'static')
    }
    
    -- Initialize game objects
    player = Player:new()
    gameState = GameState:new(sounds)
    particles = ParticleSystem:new()
end

-- Update game state
function love.update(dt)
    bgTime = bgTime + dt
    if shake.t > 0 then
        shake.t = shake.t - dt
        shake.x = love.math.random(-6, 6)
        shake.y = love.math.random(-6, 6)
    else
        shake.x, shake.y = 0, 0
    end
    
    if currentState == 'game' then
        -- Update game state
        player:update(dt, controls)
        gameState:update(dt, player)
        gameState:checkSpawnTimers(player)
        particles:update(dt)
    end
end

-- Draw game
function love.draw()
    -- Draw shared background elements for menu, options, and changeControls states
    if currentState == 'menu' or currentState == 'options' or currentState == 'changeControls' then
        -- Full screen black background
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        -- Top, bottom, left, right red borders
        love.graphics.setColor(1, 0, 0, 0.85) -- Red with some transparency
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), 3) -- Top
        love.graphics.rectangle('fill', 0, love.graphics.getHeight() - 3, love.graphics.getWidth(), 3) -- Bottom
        love.graphics.rectangle('fill', 0, 0, 3, love.graphics.getHeight()) -- Left
        love.graphics.rectangle('fill', love.graphics.getWidth() - 3, 0, 3, love.graphics.getHeight()) -- Right

        -- Simplified glitching background effect (random rectangles and lines)
        -- This aims to mimic the data stream/technical look of the Cyberpunk 2077 background
        love.graphics.setColor(0.5, 0, 0.5, 0.03) -- Faint purple for data
        for i = 1, 100 do
            local randX = math.random(love.graphics.getWidth())
            local randY = math.random(love.graphics.getHeight())
            local randW = math.random(2, 20)
            local randH = math.random(1, 3)
            love.graphics.rectangle('fill', randX, randY, randW, randH)
        end
        love.graphics.setColor(0, 1, 1, 0.02) -- Faint cyan for lines
        for i = 1, 70 do
            love.graphics.line(math.random(love.graphics.getWidth()), math.random(love.graphics.getHeight()),
                               math.random(love.graphics.getWidth()), math.random(love.graphics.getHeight()))
        end
    end

    if currentState == 'menu' then
        -- Cyberpunk 2077 like logo (text approximation)
        love.graphics.setColor(1, 1, 0) -- Yellowish color for logo
        love.graphics.setFont(fontLarge) -- Larger font for title
        love.graphics.printf('CUBE RUNNER', 50, 100, love.graphics.getWidth() - 100, 'left')

        -- Menu buttons
        local startY = love.graphics.getHeight() / 2 - (#menuButtons * 25) -- Adjust starting Y to be centered
        for i, button in ipairs(menuButtons) do
            local x = 50
            local y = startY + (i - 1) * 50
            local width = 300
            local height = 40

            if i == selectedButton then
                -- Selected button: Red outline with a blue inner glow and internal details
                love.graphics.setColor(1, 0, 0, 1) -- Bright red outline
                love.graphics.rectangle('line', x, y, width, height)
                love.graphics.setColor(0, 0.7, 1, 0.3) -- Blue inner glow (more transparent)
                love.graphics.rectangle('fill', x + 2, y + 2, width - 4, height - 4)

                -- Internal details for selected box (simplified from Cyberpunk image)
                love.graphics.setColor(0, 0.7, 1, 0.7) -- Brighter cyan for details
                love.graphics.line(x + 10, y + height / 2, x + width - 10, y + height / 2) -- Horizontal line
                love.graphics.rectangle('fill', x + width - 50, y + 10, 5, 20) -- Small block 1
                love.graphics.rectangle('fill', x + width - 40, y + 15, 5, 10) -- Small block 2
                love.graphics.rectangle('fill', x + width - 30, y + 10, 5, 20) -- Small block 3
                love.graphics.rectangle('fill', x + width - 20, y + 15, 5, 10) -- Small block 4
                love.graphics.rectangle('fill', x + width - 10, y + 10, 5, 20) -- Small block 5

                love.graphics.setColor(1, 1, 1, 1) -- White text for selected
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Grey text for unselected
            end
            love.graphics.setFont(fontMedium) -- Font for menu items
            love.graphics.printf(string.upper(button.text), x + 10, y + 5, width - 20, 'left')
        end

        -- Version number (bottom left)
        love.graphics.setColor(1, 0, 0, 0.7)
        love.graphics.setFont(fontTiny)
        love.graphics.printf('1.01', 10, love.graphics.getHeight() - 30, love.graphics.getWidth(), 'left')

    elseif currentState == 'options' then
        love.graphics.setColor(0, 1, 1)
        love.graphics.setFont(fontLarge)
        love.graphics.printf('OPTIONS', 50, 100, love.graphics.getWidth() - 100, 'left')

        local startY = love.graphics.getHeight() / 2 - (#optionsButtons * 25)
        for i, button in ipairs(optionsButtons) do
            local x = 50
            local y = startY + (i - 1) * 50
            local width = 300
            local height = 40

            if i == selectedButton then
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.rectangle('line', x, y, width, height)
                love.graphics.setColor(0, 0.7, 1, 0.3)
                love.graphics.rectangle('fill', x + 2, y + 2, width - 4, height - 4)
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            end
            love.graphics.setFont(fontMedium)
            love.graphics.printf(string.upper(button.text), x + 10, y + 5, width - 20, 'left')
        end

    elseif currentState == 'changeControls' then
        love.graphics.setColor(0, 1, 1)
        love.graphics.setFont(fontLarge)
        love.graphics.printf('CHANGE CONTROLS', 50, 100, love.graphics.getWidth() - 100, 'left')
        love.graphics.setFont(font)
        love.graphics.printf('Select a control to change:', 50, 200, love.graphics.getWidth() - 100, 'left')

        local startY = 300
        for i, option in ipairs(controlOptions) do
            local x = 50
            local y = startY + (i - 1) * 50
            local width = 300
            local height = 40

            if i == selectedButton then
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.rectangle('line', x, y, width, height)
                love.graphics.setColor(0, 0.7, 1, 0.3)
                love.graphics.rectangle('fill', x + 2, y + 2, width - 4, height - 4)
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            end
            love.graphics.setFont(fontMedium)
            love.graphics.printf(option.name .. ': ' .. controls[option.key], x + 10, y + 5, width - 20, 'left')
        end

        if changingControl then
            love.graphics.setColor(0, 1, 1)
            love.graphics.setFont(font)
            love.graphics.printf('Press a key to set as ' .. string.upper(changingControl), 50, love.graphics.getHeight() - 100, love.graphics.getWidth() - 100, 'left')
        end

    elseif currentState == 'game' then
        -- Apply screen shake only to game entities, not UI
        love.graphics.push()
        love.graphics.translate(shake.x, shake.y)
        
        -- Draw shadows
        love.graphics.setColor(0, 0, 0, 0.18)
        love.graphics.ellipse("fill", player.x, player.y + player.size/2, player.size * 0.7, player.size * 0.25)
        for _, enemy in ipairs(gameState.enemies) do
            love.graphics.ellipse("fill", enemy.x, enemy.y + enemy.size/2, enemy.size * 0.7, enemy.size * 0.25)
        end
        for _, boss in ipairs(gameState.bosses) do
            love.graphics.ellipse("fill", boss.x, boss.y + boss.size/2, boss.size * 0.7, boss.size * 0.25)
        end
        
        -- Draw player and game state entities
        player:draw()
        gameState:draw()
        particles:draw()
        
        love.graphics.pop()

        -- Draw Player UI (Brotato style) - always static relative to screen
        love.graphics.setFont(font) 

        -- Health Bar (Top Left - precise Brotato style)
        local healthBarX, healthBarY = 15, 15 -- Starting X,Y for the top-left block
        local healthBarWidth, healthBarHeight = 100, 18 -- Dimensions for the health bar section

        -- --- Combined health/level block outer thick black border ---
        -- love.graphics.setColor(0/255, 0/255, 0/255, 1) -- Black color
        -- love.graphics.setLineWidth(3) -- 3 pixels thick, as seen in screenshot
        -- Calculated total width: healthBarWidth (100) + gap (3) + level box (55) + 2 * outer border (2*3=6) = 164
        -- love.graphics.rectangle('line', healthBarX - 3, healthBarY - 3, healthBarWidth + 3 + 55 + 6, healthBarHeight + 6) 
        love.graphics.setLineWidth(1) -- Reset line width for subsequent draws

        -- --- Health bar inner red background ---
        love.graphics.setColor(180/255, 0/255, 0/255, 1) -- Dark Red (approximated from screenshot)
        love.graphics.rectangle('fill', healthBarX, healthBarY, healthBarWidth, healthBarHeight)

        -- --- Health bar green fill ---
        local currentHealthWidth = (player.health / player.maxHealth) * healthBarWidth
        love.graphics.setColor(0/255, 200/255, 0/255, 1) -- Bright Green (approximated from screenshot)
        love.graphics.rectangle('fill', healthBarX, healthBarY, currentHealthWidth, healthBarHeight)

        -- --- Health bar inner thin black border ---
        love.graphics.setColor(0/255, 0/255, 0/255, 1) -- Black border
        love.graphics.rectangle('line', healthBarX, healthBarY, healthBarWidth, healthBarHeight)

        -- --- Health text "HP / Max HP" ---
        love.graphics.setColor(255/255, 255/255, 255/255, 1) -- White text
        love.graphics.setFont(fontTiny) -- Smaller font for numbers
        -- Center text vertically within the 18px height bar. (barHeight - fontHeight)/2
        love.graphics.printf(player.health .. " / " .. player.maxHealth, healthBarX, healthBarY + (healthBarHeight - fontTiny:getHeight())/2, healthBarWidth, 'center')

        -- --- Level Indicator (Below Health Bar) ---
        local levelX = healthBarX
        local levelY = healthBarY + healthBarHeight + 3
        local levelBarOverallWidth = 150 -- Total width for the level bar as seen in the image
        local levelBarHeight = healthBarHeight

        -- Outer black border for the level bar
        love.graphics.setColor(0/255, 0/255, 0/255, 1) -- Black
        love.graphics.rectangle('line', levelX, levelY, levelBarOverallWidth, levelBarHeight)

        -- Inner grey background for the level bar
        love.graphics.setColor(50/255, 50/255, 50/255, 1) -- Dark Grey
        love.graphics.rectangle('fill', levelX + 1, levelY + 1, levelBarOverallWidth - 2, levelBarHeight - 2) -- Inner fill, accounting for border

        -- Green fill for level progress (part of the grey area)
        local greenFillWidth = 40 -- Approximate width of the green fill from the image
        love.graphics.setColor(0/255, 200/255, 0/255, 1) -- Bright Green
        love.graphics.rectangle('fill', levelX + 1, levelY + 1, greenFillWidth, levelBarHeight - 2)

        -- Level text "LVX"
        local lvText = "LV" .. player.level
        love.graphics.setColor(255/255, 255/255, 255/255, 1) -- White text
        love.graphics.setFont(fontTiny) -- Consistent font size

        -- Position LV text to the right within the grey bar, aligned to the right edge of the *bar area*
        local lvTextWidth = fontTiny:getWidth(lvText)
        local lvTextX = levelX + levelBarOverallWidth - lvTextWidth - 5 -- 5 pixels padding from right edge of the total box
        love.graphics.printf(lvText, lvTextX, levelY + (levelBarHeight - fontTiny:getHeight())/2, lvTextWidth, 'left')

        -- --- Resource Counter (Below Level block) ---
        local resourceX = healthBarX
        local resourceY = levelY + levelBarHeight + 8 -- 8-pixel vertical spacing below the level block

        -- Resource icon (drawing a diamond shape to approximate the gem/leaf)
        local iconSize = 16 -- Bounding box size for the diamond, based on screenshot proportion
        love.graphics.setColor(0/255, 0/255, 0/255, 1) -- Black outline
        love.graphics.setLineWidth(2) -- 2 pixels thick outline for icon
        -- Coordinates for a diamond centered in a 16x16 bounding box, starting at resourceX, resourceY
        love.graphics.polygon('line', resourceX + iconSize/2, resourceY,              -- Top point
                                      resourceX + iconSize, resourceY + iconSize/2,   -- Right point
                                      resourceX + iconSize/2, resourceY + iconSize,   -- Bottom point
                                      resourceX, resourceY + iconSize/2)             -- Left point
        love.graphics.setLineWidth(1) -- Reset line width

        love.graphics.setColor(0/255, 200/255, 0/255, 1) -- Bright Green fill (matching health bar fill)
        -- Filled diamond, slightly smaller to account for the outline
        love.graphics.polygon('fill', resourceX + iconSize/2, resourceY + 1, 
                                      resourceX + iconSize - 1, resourceY + iconSize/2, 
                                      resourceX + iconSize/2, resourceY + iconSize - 1, 
                                      resourceX + 1, resourceY + iconSize/2)
        
        -- --- Score text next to resource icon ---
        love.graphics.setColor(255/255, 255/255, 255/255, 1) -- White text
        love.graphics.setFont(fontSmall) -- Font for score (20pt)
        -- Vertically center with icon. (iconSize - font_height)/2. Adjusted Y position slightly for visual balance.
        love.graphics.print(gameState.score, resourceX + iconSize + 8, resourceY + (iconSize - fontSmall:getHeight())/2 - 1)

        -- Wave and Time Information (Top Center) - matching provided image
        love.graphics.setColor(1, 1, 1, 1) -- White color for the text
        
        -- Display "WAVE X"
        love.graphics.setFont(font) 
        local waveText = "WAVE " .. gameState.wave
        love.graphics.printf(waveText, 0, 15, love.graphics.getWidth(), 'center') 

        -- Display large time number below
        love.graphics.setFont(fontLarge)
        -- Calculate Y position: 15 (initial Y) + font:getHeight() (height of first line) + 5 (small gap)
        love.graphics.printf(math.floor(gameState.gameTime), 0, 15 + font:getHeight() + 5, love.graphics.getWidth(), 'center') 

    end
end

-- Handle key presses
function love.keypressed(key)
    if currentState == 'menu' then
        if key == 'up' or key == 'w' then
            selectedButton = (selectedButton - 2) % #menuButtons + 1
        elseif key == 'down' or key == 's' then
            selectedButton = selectedButton % #menuButtons + 1
        elseif key == 'return' or key == 'space' then
            menuButtons[selectedButton].action()
        end
    elseif currentState == 'options' then
        if key == 'up' or key == 'w' then
            selectedButton = (selectedButton - 2) % #optionsButtons + 1
        elseif key == 'down' or key == 's' then
            selectedButton = selectedButton % #optionsButtons + 1
        elseif key == 'return' or key == 'space' then
            optionsButtons[selectedButton].action()
        end
    elseif currentState == 'changeControls' then
        if changingControl then
            controls[changingControl] = key
            changingControl = nil
        else
            if key == 'up' or key == 'w' then
                selectedButton = (selectedButton - 2) % #controlOptions + 1
            elseif key == 'down' or key == 's' then
                selectedButton = selectedButton % #controlOptions + 1
            elseif key == 'return' or key == 'space' then
                changingControl = controlOptions[selectedButton].key
            elseif key == 'escape' or key == 'backspace' then
                currentState = 'options'
            end
        end
    elseif currentState == 'game' then
        if key == controls.dash then
            player:startDash()
        end
    end
end 
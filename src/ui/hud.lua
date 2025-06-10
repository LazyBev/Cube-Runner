local Constants = require("utils.constants")

local HUD = {
    fonts = {
        small = nil,
        medium = nil,
        large = nil
    },
    scale = 0.8,
    padding = 12,
    barHeight = 18,
    barWidth = 180,
    animations = {
        combo = {
            scale = 1,
            alpha = 1,
            glow = 0
        },
        health = {
            flash = 0
        },
        score = {
            bounce = 0
        }
    }
}

function HUD.updateLayout()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    -- Calculate scale based on window size with reduced base scale
    HUD.scale = math.min(w / 1280, h / 720) * 0.8
    
    -- Update fonts with smaller sizes
    HUD.fonts.small = love.graphics.newFont(math.min(10 * HUD.scale, h * 0.015))
    HUD.fonts.medium = love.graphics.newFont(math.min(14 * HUD.scale, h * 0.02))
    HUD.fonts.large = love.graphics.newFont(math.min(20 * HUD.scale, h * 0.03))
    
    -- Update bar dimensions with smaller sizes
    HUD.barWidth = math.min(180 * HUD.scale, w * 0.25)
    HUD.padding = math.min(12 * HUD.scale, w * 0.015)
    HUD.barHeight = math.min(18 * HUD.scale, h * 0.025)
end

function HUD.update(dt)
    -- Update combo animation
    local comboAnim = HUD.animations.combo
    comboAnim.scale = 1 + math.sin(love.timer.getTime() * 5) * 0.1
    comboAnim.glow = math.sin(love.timer.getTime() * 3) * 0.5 + 0.5
    
    -- Update health flash animation
    HUD.animations.health.flash = math.max(0, HUD.animations.health.flash - dt * 5)
    
    -- Update score bounce animation
    HUD.animations.score.bounce = math.max(0, HUD.animations.score.bounce - dt * 5)
end

function HUD.drawBar(x, y, width, height, value, maxValue, color, label, showValue)
    -- Draw bar background with modern gradient
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, width, height, 
        math.min(5 * HUD.scale, 5), math.min(5 * HUD.scale, 5))
    
    -- Draw bar fill with enhanced gradient
    if value > 0 then
        local fillWidth = (value / maxValue) * width
        
        -- Main fill
        love.graphics.setColor(color[1], color[2], color[3], 0.8)
        love.graphics.rectangle("fill", x, y, fillWidth, height, 
            math.min(5 * HUD.scale, 5), math.min(5 * HUD.scale, 5))
        
        -- Gradient overlay
        local gradient = love.graphics.newMesh({
            {x, y, 0, 0, color[1], color[2], color[3], 0.9},
            {x + fillWidth, y, 0, 0, color[1], color[2], color[3], 0.7},
            {x, y + height, 0, 0, color[1], color[2], color[3], 0.7},
            {x + fillWidth, y + height, 0, 0, color[1], color[2], color[3], 0.5}
        }, "strip", "static")
        love.graphics.draw(gradient)
        
        -- Shine effect
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("fill", x, y, fillWidth, height * 0.3, 
            math.min(5 * HUD.scale, 5), math.min(5 * HUD.scale, 5))
    end
    
    -- Draw bar border with enhanced glow
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setLineWidth(2 * HUD.scale)
    love.graphics.rectangle("line", x, y, width, height, 
        math.min(5 * HUD.scale, 5), math.min(5 * HUD.scale, 5))
    
    -- Draw label and value with enhanced typography
    if label then
        love.graphics.setFont(HUD.fonts.medium)
        love.graphics.setColor(1, 1, 1, 0.9)
        if showValue then
            -- Draw text shadow
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.printf(string.format("%s: %d/%d", label, value, maxValue),
                x + 1, y + height/2 - HUD.fonts.medium:getHeight()/2 + 1, width, "center")
            
            -- Draw main text
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.printf(string.format("%s: %d/%d", label, value, maxValue),
                x, y + height/2 - HUD.fonts.medium:getHeight()/2, width, "center")
        else
            -- Draw text shadow
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.printf(label,
                x + 1, y + height/2 - HUD.fonts.medium:getHeight()/2 + 1, width, "center")
            
            -- Draw main text
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.printf(label,
                x, y + height/2 - HUD.fonts.medium:getHeight()/2, width, "center")
        end
    end
end

function HUD.draw(gameState)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Draw player health bars with compact layout
    for i, player in ipairs(gameState.players) do
        local x = i == 1 and HUD.padding or w - HUD.barWidth - HUD.padding
        local y = HUD.padding
        
        -- Health bar with compact design
        HUD.drawBar(x, y, HUD.barWidth, HUD.barHeight, 
            player.health, player.maxHealth, player.color, "HP", true)
        
        -- Dash cooldown with compact design
        local cooldownY = y + HUD.barHeight * 1.1
        HUD.drawBar(x, cooldownY, HUD.barWidth, HUD.barHeight * 0.35,
            player.dashCooldown, player.class.dashCooldown, {0.2, 0.2, 0.9}, 
            string.format("Dash: %.1fs", player.dashCooldown), false)
        
        -- Ability uses with compact design
        local abilityY = y + HUD.barHeight * 1.3 + 2
        HUD.drawBar(x, abilityY, HUD.barWidth, HUD.barHeight * 0.35,
            player.abilityUses or 0, player.class.ability.uses, {0.9, 0.2, 0.2},
            string.format("Ability: %d/%d", player.abilityUses or 0, player.class.ability.uses), false)
    end
    
    -- Draw combo with compact design
    if gameState.combo and gameState.combo > 1 then
        local comboAnim = HUD.animations.combo
        love.graphics.setFont(HUD.fonts.medium)
        local comboText = string.format("%dx", gameState.combo)
        
        -- Enhanced combo glow
        love.graphics.setColor(1, 1, 0, 0.3 * comboAnim.glow)
        for i = 1, 4 do
            love.graphics.printf(comboText,
                0, h - h * 0.1 + i, w, "center")
            love.graphics.printf(comboText,
                0, h - h * 0.1 - i, w, "center")
            love.graphics.printf(comboText,
                i, h - h * 0.1, w, "center")
            love.graphics.printf(comboText,
                -i, h - h * 0.1, w, "center")
        end
        
        -- Main combo text with enhanced animation
        love.graphics.setColor(1, 1, 0)
        love.graphics.push()
        love.graphics.translate(w/2, h - h * 0.1)
        love.graphics.scale(comboAnim.scale)
        love.graphics.printf(comboText, -w/2, -HUD.fonts.medium:getHeight()/2, w, "center")
        love.graphics.pop()
    end
    
    -- Draw score with compact design
    local scoreWidth = math.min(150 * HUD.scale, w * 0.15)
    local scoreHeight = HUD.barHeight * 0.8
    local scoreBounce = HUD.animations.score.bounce
    
    -- Score background with gradient
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", w/2 - scoreWidth/2, HUD.padding - scoreBounce, 
        scoreWidth, scoreHeight, math.min(4 * HUD.scale, 4), math.min(4 * HUD.scale, 4))
    
    -- Score border with glow
    love.graphics.setColor(0.3, 0.7, 1, 0.5)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", w/2 - scoreWidth/2, HUD.padding - scoreBounce, 
        scoreWidth, scoreHeight, math.min(4 * HUD.scale, 4), math.min(4 * HUD.scale, 4))
    
    -- Score text with enhanced typography
    love.graphics.setFont(HUD.fonts.small)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf(string.format("Score: %d", gameState.score or 0),
        w/2 - scoreWidth/2, HUD.padding - scoreBounce + (scoreHeight - HUD.fonts.small:getHeight())/2,
        scoreWidth, "center")
    
    -- Draw game time with modern design
    local gameTime = gameState.gameTime or 0
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    local timeWidth = math.min(200 * HUD.scale, w * 0.2)
    local timeHeight = HUD.barHeight * 0.8
    
    HUD.drawBar(w/2 - timeWidth/2, HUD.padding + scoreHeight + 5,
        timeWidth, timeHeight, 1, 1, {0.2, 0.2, 0.2},
        string.format("Time: %02d:%02d", minutes, seconds), false)
    
    -- Draw max combo with enhanced visuals
    if gameState.maxCombo and gameState.maxCombo > 1 then
        local maxComboWidth = math.min(200 * HUD.scale, w * 0.2)
        local maxComboHeight = HUD.barHeight * 0.8
        
        HUD.drawBar(w/2 - maxComboWidth/2, HUD.padding + scoreHeight + timeHeight + 10,
            maxComboWidth, maxComboHeight, 1, 1, {0.2, 0.2, 0.2},
            string.format("Max Combo: %dx", gameState.maxCombo), false)
    end
end

function HUD.onScoreChange()
    HUD.animations.score.bounce = 10
end

function HUD.onHealthChange()
    HUD.animations.health.flash = 1
end

return HUD 
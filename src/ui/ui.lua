local UI = {}

local fonts = {
    small = nil,
    medium = nil,
    large = nil
}

function UI.init()
    fonts.small = love.graphics.newFont(16)
    fonts.medium = love.graphics.newFont(24)
    fonts.large = love.graphics.newFont(32)
end

function UI.drawGame(gameState)
    -- Draw score
    love.graphics.setFont(fonts.medium)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Score: " .. gameState.score, 20, 20, 200, "left")
    
    -- Draw wave info
    love.graphics.printf("Wave: " .. gameState.wave, love.graphics.getWidth() - 220, 20, 200, "right")
    
    -- Draw player stats
    if gameState.player then
        local player = gameState.player
        local statsY = 60
        
        -- Draw health bar
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 20, statsY, 200, 20)
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.rectangle("fill", 20, statsY, 200 * (player.health / player.maxHealth), 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonts.small)
        love.graphics.printf("Health: " .. player.health .. "/" .. player.maxHealth, 20, statsY, 200, "center")
        
        -- Draw stats
        statsY = statsY + 40
        love.graphics.printf(string.format(
            "Damage: %d\nDash Damage: %d\nSpeed: %d\nDash Speed: %d",
            player.damage,
            player.dashDamage,
            player.speed,
            player.dashSpeed
        ), 20, statsY, 200, "left")
        
        -- Draw dash cooldown
        if not player.canDash then
            local cooldownPercent = player.dashCooldownTimer / player.dashCooldown
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", 20, statsY + 100, 200, 10)
            love.graphics.setColor(0.8, 0.8, 0.2)
            love.graphics.rectangle("fill", 20, statsY + 100, 200 * (1 - cooldownPercent), 10)
        end
    end
    
    -- Draw wave progress
    local waveInfo = WaveManager.getWaveInfo(gameState.wave)
    if waveInfo.isBossWave then
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.setFont(fonts.large)
        love.graphics.printf("BOSS WAVE!", 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")
    end
    
    -- Draw enemy count
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.medium)
    love.graphics.printf("Enemies: " .. #gameState.enemies, 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
    
    -- Draw controls
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("WASD: Move | SPACE: Dash", 20, love.graphics.getHeight() - 30, 300, "left")
end

function UI.drawGameOver(score, wave)
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw game over text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.large)
    love.graphics.printf("Game Over", 0, love.graphics.getHeight()/2 - 100, love.graphics.getWidth(), "center")
    
    -- Draw stats
    love.graphics.setFont(fonts.medium)
    love.graphics.printf(string.format("Score: %d\nWave: %d", score, wave), 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")
    
    -- Draw restart instructions
    love.graphics.setFont(fonts.small)
    love.graphics.printf("Press R to restart", 0, love.graphics.getHeight()/2 + 100, love.graphics.getWidth(), "center")
end

return UI 
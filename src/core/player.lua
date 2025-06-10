local Constants = require("utils.constants")

local Player = {
    lastDirection = {x = 0, y = 0}  -- Track last movement direction
}

function Player.initialize(id)
    local player = {
        id = id,
        x = id == 1 and 100 or love.graphics.getWidth() - 100,
        y = love.graphics.getHeight() / 2,
        size = 30,
        speed = 200,
        health = 100,
        color = Constants.COLOR_PRESETS[id].color,
        isDashing = false,
        dashCooldown = 0,
        dashCooldownMax = 1.5,
        dashSpeed = 500,
        dashDuration = 0.2,
        dashTimer = 0,
        dashTarget = {x = 0, y = 0},
        trail = {},
        trailMaxLength = 10,
        dashTrail = {},  -- New dash trail for damage
        dashTrailDuration = 0.3,  -- How long the trail stays active
        keybinds = {
            up = id == 1 and "w" or "up",
            down = id == 1 and "s" or "down",
            left = id == 1 and "a" or "left",
            right = id == 1 and "d" or "right",
            dash = id == 1 and "space" or "return",
            ability = id == 1 and "q" or "p"
        },
        ability = {
            active = false,
            cooldown = 0,
            cooldownMax = 10,
            uses = 3,
            maxUses = 3
        },
        lastDirection = {x = 0, y = 0},  -- Track last movement direction for each player
        lastPosition = {x = 0, y = 0}    -- Track last position for trail
    }
    
    -- Set player class
    local class = Constants.PLAYER_CLASSES[1] -- Default to Warrior
    player.health = class.health
    player.speed = class.speed
    player.dashCooldownMax = class.dashCooldown
    player.ability.name = class.ability.name
    player.ability.description = class.ability.description
    player.ability.cooldownMax = class.ability.cooldown
    player.ability.duration = class.ability.duration
    player.ability.uses = class.ability.uses
    player.ability.maxUses = class.ability.uses
    
    return player
end

function Player.update(player, dt, obstacles, otherPlayer)
    -- Update dash cooldown
    if player.dashCooldown > 0 then
        player.dashCooldown = player.dashCooldown - dt
    end
    
    -- Update ability cooldown
    if player.ability.cooldown > 0 then
        player.ability.cooldown = player.ability.cooldown - dt
    end
    
    -- Store last position for trail
    player.lastPosition.x = player.x
    player.lastPosition.y = player.y
    
    -- Handle movement
    if not player.isDashing then
        local dx, dy = 0, 0
        
        if love.keyboard.isDown(player.keybinds.up) then
            dy = dy - 1
        end
        if love.keyboard.isDown(player.keybinds.down) then
            dy = dy + 1
        end
        if love.keyboard.isDown(player.keybinds.left) then
            dx = dx - 1
        end
        if love.keyboard.isDown(player.keybinds.right) then
            dx = dx + 1
        end
        
        -- Update last direction if moving
        if dx ~= 0 or dy ~= 0 then
            -- Normalize diagonal movement
            if dx ~= 0 and dy ~= 0 then
                dx = dx * 0.7071 -- 1/sqrt(2)
                dy = dy * 0.7071
            end
            player.lastDirection.x = dx
            player.lastDirection.y = dy
        end
        
        -- Move player with collision detection
        local newX = player.x + dx * player.speed * dt
        local newY = player.y + dy * player.speed * dt
        
        -- Try X movement first
        local canMoveX = true
        for _, obstacle in ipairs(obstacles) do
            if Player.checkCollision({x = newX, y = player.y, size = player.size}, obstacle) then
                canMoveX = false
                Player.handleCollision(player, obstacle, dt)
                break
            end
        end
        if canMoveX then player.x = newX end
        
        -- Then try Y movement
        local canMoveY = true
        for _, obstacle in ipairs(obstacles) do
            if Player.checkCollision({x = player.x, y = newY, size = player.size}, obstacle) then
                canMoveY = false
                Player.handleCollision(player, obstacle, dt)
                break
            end
        end
        if canMoveY then player.y = newY end
        
    else
        -- Handle dash movement with collision detection
        player.dashTimer = player.dashTimer - dt
        if player.dashTimer <= 0 then
            player.isDashing = false
            player.dashCooldown = player.dashCooldownMax
        else
            local dx = player.dashTarget.x - player.x
            local dy = player.dashTarget.y - player.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                dx = dx / dist
                dy = dy / dist
                local newX = player.x + dx * player.dashSpeed * dt
                local newY = player.y + dy * player.dashSpeed * dt
                
                -- Check for collisions during dash
                local canMove = true
                for _, obstacle in ipairs(obstacles) do
                    if Player.checkCollision({x = newX, y = newY, size = player.size}, obstacle) then
                        canMove = false
                        player.isDashing = false
                        player.dashCooldown = player.dashCooldownMax
                        break
                    end
                end
                
                if canMove then
                    player.x = newX
                    player.y = newY
                    
                    -- Add dash trail segment
                    table.insert(player.dashTrail, {
                        x = player.x,
                        y = player.y,
                        angle = math.atan2(dy, dx),
                        timer = player.dashTrailDuration
                    })
                end
            end
        end
    end
    
    -- Update dash trail
    for i = #player.dashTrail, 1, -1 do
        local segment = player.dashTrail[i]
        segment.timer = segment.timer - dt
        
        -- Check for collision with other player
        if otherPlayer and not otherPlayer.isDashing then
            local dx = otherPlayer.x - segment.x
            local dy = otherPlayer.y - segment.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < player.size then
                otherPlayer.health = math.max(0, otherPlayer.health - 10)
                -- Add hit effect
                table.remove(player.dashTrail, i)
            end
        end
        
        -- Remove expired trail segments
        if segment.timer <= 0 then
            table.remove(player.dashTrail, i)
        end
    end
    
    -- Update trail
    table.insert(player.trail, {x = player.x, y = player.y})
    if #player.trail > player.trailMaxLength then
        table.remove(player.trail, 1)
    end
end

function Player.draw(player)
    -- Draw dash trail
    if #player.dashTrail > 0 then
        for i, segment in ipairs(player.dashTrail) do
            local alpha = segment.timer / player.dashTrailDuration
            love.graphics.setColor(player.color[1], player.color[2], player.color[3], alpha * 0.8)
            
            -- Draw beam segment
            love.graphics.push()
            love.graphics.translate(segment.x, segment.y)
            love.graphics.rotate(segment.angle)
            love.graphics.rectangle("fill", 0, -player.size/2, player.size * 2, player.size)
            love.graphics.pop()
            
            -- Draw glow effect
            love.graphics.setColor(player.color[1], player.color[2], player.color[3], alpha * 0.3)
            love.graphics.push()
            love.graphics.translate(segment.x, segment.y)
            love.graphics.rotate(segment.angle)
            love.graphics.rectangle("fill", 0, -player.size, player.size * 2, player.size * 2)
            love.graphics.pop()
        end
    end
    
    -- Draw player
    love.graphics.setColor(player.color)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
    
    -- Draw trail
    for i, pos in ipairs(player.trail) do
        local alpha = i / #player.trail
        love.graphics.setColor(player.color[1], player.color[2], player.color[3], alpha * 0.3)
        love.graphics.rectangle("fill", pos.x, pos.y, player.size, player.size)
    end
end

function Player.startDash(player)
    if player.dashCooldown <= 0 and not player.isDashing then
        -- Use last movement direction for dash if no mouse input
        local targetX, targetY
        
        if player.lastDirection.x ~= 0 or player.lastDirection.y ~= 0 then
            -- Dash in last movement direction
            local dashDistance = 200
            targetX = player.x + player.lastDirection.x * dashDistance
            targetY = player.y + player.lastDirection.y * dashDistance
        else
            -- Default dash forward if no direction
            targetX = player.x + 200
            targetY = player.y
        end
        
        -- Ensure target is within screen bounds
        targetX = math.max(0, math.min(targetX, love.graphics.getWidth() - player.size))
        targetY = math.max(0, math.min(targetY, love.graphics.getHeight() - player.size))
        
        player.isDashing = true
        player.dashTimer = player.dashDuration
        player.dashTarget = {x = targetX, y = targetY}
    end
end

function Player.activateAbility(player)
    if player.ability.uses > 0 and player.ability.cooldown <= 0 then
        player.ability.active = true
        player.ability.uses = player.ability.uses - 1
        player.ability.cooldown = player.ability.cooldownMax
        -- Add ability particles
        -- Play ability sound
    end
end

function Player.checkCollision(player, obstacle)
    return player.x < obstacle.x + obstacle.width and
           player.x + player.size > obstacle.x and
           player.y < obstacle.y + obstacle.height and
           player.y + player.size > obstacle.y
end

function Player.handleCollision(player, obstacle, dt)
    -- Calculate overlap on each axis
    local overlapX = math.min(player.x + player.size - obstacle.x, obstacle.x + obstacle.width - player.x)
    local overlapY = math.min(player.y + player.size - obstacle.y, obstacle.y + obstacle.height - player.y)
    
    -- Resolve collision on the axis with smaller overlap
    if overlapX < overlapY then
        if player.x < obstacle.x then
            player.x = obstacle.x - player.size
        else
            player.x = obstacle.x + obstacle.width
        end
    else
        if player.y < obstacle.y then
            player.y = obstacle.y - player.size
        else
            player.y = obstacle.y + obstacle.height
        end
    end
end

function Player.findValidDashTarget(player, targetX, targetY)
    local dx = targetX - player.x
    local dy = targetY - player.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 0 then
        dx = dx / dist
        dy = dy / dist
        local maxDashDistance = 200
        local targetX = player.x + dx * maxDashDistance
        local targetY = player.y + dy * maxDashDistance
        
        -- Ensure target is within screen bounds
        targetX = math.max(0, math.min(targetX, love.graphics.getWidth() - player.size))
        targetY = math.max(0, math.min(targetY, love.graphics.getHeight() - player.size))
        
        return {
            x = targetX,
            y = targetY
        }
    end
    return nil
end

-- Networking stub for future MMORPG
function Player.syncToServer(player)
    -- TODO: Send player state to server
end

function Player.syncFromServer(player, data)
    -- TODO: Update player state from server data
end

return Player 
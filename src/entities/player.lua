local Player = {
    trails = {},
    maxTrailLength = 10,
    trailFadeTime = 0.5
}

-- RPG class definitions
Player.CLASSES = {
    WARRIOR = {
        name = "Warrior",
        baseHealth = 150,
        baseSpeed = 200,
        basePower = 10,
        ability = { name = "Berserk", desc = "Double power for 5s" }
    },
    MAGE = {
        name = "Mage",
        baseHealth = 100,
        baseSpeed = 220,
        basePower = 8,
        ability = { name = "Fireball", desc = "Shoot a fireball" }
    },
    ROGUE = {
        name = "Rogue",
        baseHealth = 120,
        baseSpeed = 260,
        basePower = 7,
        ability = { name = "Dash", desc = "Quickly dash forward" }
    }
}

function Player.initialize(player)
    -- Set initial position
    player.x = 100
    player.y = 100
    
    -- Set initial stats
    player.health = player.class.baseHealth
    player.maxHealth = player.class.baseHealth
    player.speed = player.class.baseSpeed
    player.power = player.class.basePower
    
    -- Initialize cooldowns
    player.dashCooldown = 0
    player.abilityCooldown = 0
    
    -- Initialize state
    player.isDashing = false
    player.abilityActive = false
    player.abilityDuration = 0
    
    -- Initialize inventory
    player.inventory = {}
    player.gold = 0
    
    -- Initialize experience
    player.level = 1
    player.xp = 0
    player.xpToNext = 100
    
    -- Set color based on class
    if player.class.name == "Warrior" then
        player.color = {1, 0.3, 0.3}  -- Red
    elseif player.class.name == "Mage" then
        player.color = {0.3, 0.3, 1}  -- Blue
    elseif player.class.name == "Rogue" then
        player.color = {0.3, 1, 0.3}  -- Green
    else
        player.color = {1, 1, 1}  -- White
    end
    
    return player
end

function Player.new(class)
    class = class or Player.CLASSES.WARRIOR
    return {
        class = class,
        name = class.name,
        level = 1,
        xp = 0,
        xpToNext = 100,
        health = class.baseHealth,
        maxHealth = class.baseHealth,
        speed = class.baseSpeed,
        power = class.basePower,
        ability = class.ability,
        abilityCooldown = 0,
        inventory = {},
        gold = 0,
        x = 100,
        y = 100,
        size = 24,
        isDashing = false,
        dashCooldown = 0,
        abilityActive = false,
        abilityDuration = 0,
        keybinds = {
            up = "w", down = "s", left = "a", right = "d", dash = "space", ability = "q"
        },
        color = {1, 1, 1},
        lastHitTime = 0
    }
end

function Player.gainXP(player, amount)
    player.xp = player.xp + amount
    while player.xp >= player.xpToNext do
        player.xp = player.xp - player.xpToNext
        player.level = player.level + 1
        player.xpToNext = math.floor(player.xpToNext * 1.2)
        player.maxHealth = player.maxHealth + 10
        player.health = player.maxHealth
        player.power = player.power + 2
        player.speed = player.speed + 2
    end
end

function Player.addItem(player, item)
    table.insert(player.inventory, item)
end

function Player.useAbility(player)
    if player.abilityCooldown <= 0 then
        player.abilityActive = true
        player.abilityDuration = 3
        player.abilityCooldown = 10
        -- Ability effect logic here
    end
end

function Player.update(player, dt, obstacles)
    -- Cooldowns
    if player.dashCooldown > 0 then player.dashCooldown = player.dashCooldown - dt end
    if player.abilityCooldown > 0 then player.abilityCooldown = player.abilityCooldown - dt end
    if player.abilityActive then
        player.abilityDuration = player.abilityDuration - dt
        if player.abilityDuration <= 0 then player.abilityActive = false end
    end
    -- Movement (same as before, but use player.speed)
    local speed = player.speed
    if player.isDashing then speed = speed * 2 end
    if love.keyboard.isDown(player.keybinds.up) then player.y = player.y - speed * dt end
    if love.keyboard.isDown(player.keybinds.down) then player.y = player.y + speed * dt end
    if love.keyboard.isDown(player.keybinds.left) then player.x = player.x - speed * dt end
    if love.keyboard.isDown(player.keybinds.right) then player.x = player.x + speed * dt end
    player.x = math.max(0, math.min(player.x, love.graphics.getWidth() - player.size))
    player.y = math.max(0, math.min(player.y, love.graphics.getHeight() - player.size))
    -- Inventory and other RPG logic can be expanded here

    -- Update trail
    table.insert(Player.trails, {
        x = player.x,
        y = player.y,
        color = player.color,
        life = Player.trailFadeTime
    })
    
    -- Remove old trail segments
    while #Player.trails > Player.maxTrailLength do
        table.remove(Player.trails, 1)
    end
    
    -- Update trail life
    for i = #Player.trails, 1, -1 do
        Player.trails[i].life = Player.trails[i].life - dt
        if Player.trails[i].life <= 0 then
            table.remove(Player.trails, i)
        end
    end

    -- Check collisions with obstacles
    for _, obstacle in ipairs(obstacles) do
        if Player.checkCollision(player, obstacle) then
            player.health = player.health - obstacle.damage
            player.lastHitTime = love.timer.getTime()
            -- Create hit particles
            Particles.addHitParticles(player.x, player.y, player.color)
        end
    end
end

function Player.draw(player)
    -- Draw player (with class color)
    love.graphics.setColor(player.color)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
    -- Draw name and level
    love.graphics.setColor(1,1,1)
    love.graphics.print(player.name .. " Lv." .. player.level, player.x, player.y - 18)

    -- Draw trail
    for i, trail in ipairs(Player.trails) do
        local alpha = trail.life / Player.trailFadeTime
        love.graphics.setColor(trail.color[1], trail.color[2], trail.color[3], alpha * 0.5)
        love.graphics.rectangle("fill", trail.x, trail.y, player.size, player.size)
    end

    -- Draw player glow
    love.graphics.setColor(player.color[1], player.color[2], player.color[3], 0.3)
    love.graphics.circle("fill", player.x + player.size/2, player.y + player.size/2, player.size * 1.2)
    
    -- Draw ability effects
    if player.abilityActive then
        -- Pulsing shield effect
        local pulse = math.sin(love.timer.getTime() * 10) * 0.2 + 0.8
        love.graphics.setColor(player.color[1], player.color[2], player.color[3], 0.3 * pulse)
        love.graphics.circle("fill", player.x + player.size/2, player.y + player.size/2, player.size * 2)
        
        -- Energy particles
        for i = 1, 8 do
            local angle = love.timer.getTime() * 2 + (i * math.pi / 4)
            local radius = player.size * 1.5
            local x = player.x + player.size/2 + math.cos(angle) * radius
            local y = player.y + player.size/2 + math.sin(angle) * radius
            love.graphics.setColor(player.color[1], player.color[2], player.color[3], 0.6)
            love.graphics.circle("fill", x, y, 3)
        end
    end
    
    -- Draw dash effect
    if player.isDashing then
        love.graphics.setColor(player.color[1], player.color[2], player.color[3], 0.5)
        love.graphics.circle("fill", player.x + player.size/2, player.y + player.size/2, player.size * 1.5)
    end
end

function Player.startDash(player)
    if player.dashCooldown <= 0 then
        player.isDashing = true
        -- Use class dash cooldown if available, otherwise use default
        player.dashCooldown = player.class and player.class.dashCooldown or 1.0
        -- Create dash particles
        Particles.addDashParticles(player)
        -- Reset dash after a short duration
        Timer.after(0.2, function()
            player.isDashing = false
        end)
    end
end

function Player.activateAbility(player)
    if player.abilityUses > 0 then
        player.abilityActive = true
        player.abilityUses = player.abilityUses - 1
        -- Use class ability duration if available, otherwise use default
        player.abilityDuration = player.class and player.class.ability.duration or 3.0
        -- Create ability activation particles
        Particles.addHitParticles(player.x, player.y, player.color)
    end
end

function Player.checkCollision(player, obstacle)
    return player.x < obstacle.x + obstacle.width and
           player.x + player.size > obstacle.x and
           player.y < obstacle.y + obstacle.height and
           player.y + player.size > obstacle.y
end

return Player 
local Shop = {}

-- Shop items
local items = {
    {
        name = "Damage Up",
        description = "Increase damage by 5",
        cost = 100,
        type = "damage",
        amount = 1
    },
    {
        name = "Speed Up",
        description = "Increase speed by 20",
        cost = 100,
        type = "speed",
        amount = 1
    },
    {
        name = "Dash Damage Up",
        description = "Increase dash damage by 10",
        cost = 150,
        type = "dashDamage",
        amount = 1
    },
    {
        name = "Health Up",
        description = "Increase max health by 20",
        cost = 150,
        type = "health",
        amount = 1
    },
    {
        name = "Dash Cooldown",
        description = "Reduce dash cooldown by 0.2s",
        cost = 200,
        type = "dashCooldown",
        amount = 0.2
    }
}

local selectedItem = 1
local shopOpen = false

function Shop.init()
    selectedItem = 1
    shopOpen = false
end

function Shop.open()
    shopOpen = true
    selectedItem = 1
end

function Shop.close()
    shopOpen = false
end

function Shop.draw()
    if not shopOpen then return end
    
    -- Draw shop background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", 100, 100, love.graphics.getWidth() - 200, love.graphics.getHeight() - 200)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Shop", 100, 120, love.graphics.getWidth() - 200, "center")
    
    -- Draw items
    love.graphics.setFont(love.graphics.newFont(16))
    for i, item in ipairs(items) do
        local y = 180 + (i - 1) * 60
        
        -- Draw selection highlight
        if i == selectedItem then
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", 120, y - 5, love.graphics.getWidth() - 240, 50)
        end
        
        -- Draw item
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(item.name, 140, y, 300, "left")
        love.graphics.printf(item.description, 140, y + 20, 300, "left")
        love.graphics.printf(item.cost .. " coins", love.graphics.getWidth() - 340, y + 10, 200, "right")
    end
    
    -- Draw instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Use UP/DOWN to select, ENTER to buy, ESC to close", 100, love.graphics.getHeight() - 120, love.graphics.getWidth() - 200, "center")
end

function Shop.handleInput(key)
    if not shopOpen then return end
    
    if key == "up" then
        selectedItem = math.max(1, selectedItem - 1)
    elseif key == "down" then
        selectedItem = math.min(#items, selectedItem + 1)
    elseif key == "return" then
        Shop.purchaseItem(selectedItem)
    elseif key == "escape" then
        Shop.close()
        gameState.currentState = states.GAME
    end
end

function Shop.handleClick(x, y, button)
    if not shopOpen then return end
    
    -- Check if click is within shop area
    if x >= 100 and x <= love.graphics.getWidth() - 100 and
       y >= 100 and y <= love.graphics.getHeight() - 100 then
        
        -- Calculate which item was clicked
        local itemY = 180
        for i = 1, #items do
            if y >= itemY and y <= itemY + 50 then
                selectedItem = i
                if button == 1 then -- Left click
                    Shop.purchaseItem(i)
                end
                break
            end
            itemY = itemY + 60
        end
    end
end

function Shop.purchaseItem(index)
    local item = items[index]
    if gameState.score >= item.cost then
        gameState.score = gameState.score - item.cost
        gameState.player:applyUpgrade(item.type, item.amount)
        
        -- Increase cost for next purchase
        item.cost = math.floor(item.cost * 1.5)
    end
end

return Shop 
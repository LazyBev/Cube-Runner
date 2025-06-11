local MenuSystem = {
    currentMenu = "main",
    selectedIndex = 1,
    menuItems = {
        main = {
            {text = "Play", action = "start_game"},
            {text = "Settings", action = "settings"},
            {text = "Credits", action = "credits"},
            {text = "Exit", action = "exit"}
        },
        settings = {
            {text = "Music Volume", type = "slider", value = 0.7, min = 0, max = 1},
            {text = "SFX Volume", type = "slider", value = 0.7, min = 0, max = 1},
            {text = "Back", action = "back"}
        },
        credits = {
            {text = "Created by LazyBev", type = "text"},
            {text = "Back", action = "back"}
        }
    },
    title = "CUBE RUNNER",
    titleScale = 1,
    titlePulse = 0,
    titleColor = {1, 1, 1},
    menuColor = {1, 1, 1},
    hoverColor = {0.8, 0.8, 1},
    selectedColor = {0.6, 0.6, 1},
    time = 0,
    cardRotation = 0,
    cardScale = 1,
    cardHover = false
}

function MenuSystem.update(dt)
    MenuSystem.time = MenuSystem.time + dt
    MenuSystem.titlePulse = math.sin(MenuSystem.time * 2) * 0.1 + 0.9
    MenuSystem.titleScale = 1 + math.sin(MenuSystem.time * 3) * 0.05
    
    -- Update card animation
    MenuSystem.cardRotation = math.sin(MenuSystem.time) * 0.1
    MenuSystem.cardScale = 1 + math.sin(MenuSystem.time * 2) * 0.05
    
    -- Update colors
    local t = MenuSystem.time
    MenuSystem.titleColor = {
        0.8 + math.sin(t) * 0.2,
        0.8 + math.sin(t + 2) * 0.2,
        1.0
    }
    
    MenuSystem.menuColor = {
        0.9 + math.sin(t + 1) * 0.1,
        0.9 + math.sin(t + 3) * 0.1,
        1.0
    }
    
    MenuSystem.hoverColor = {
        0.7 + math.sin(t + 2) * 0.3,
        0.7 + math.sin(t + 4) * 0.3,
        1.0
    }
    
    MenuSystem.selectedColor = {
        0.5 + math.sin(t + 3) * 0.5,
        0.5 + math.sin(t + 5) * 0.5,
        1.0
    }
end

function MenuSystem.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Draw Balatro-style background
    Shaders.applyBalatroBg(function()
        love.graphics.rectangle("fill", 0, 0, w, h)
    end)
    
    -- Draw title with card glow effect
    love.graphics.push()
    love.graphics.translate(w/2, h/4)
    love.graphics.rotate(MenuSystem.cardRotation)
    love.graphics.scale(MenuSystem.titleScale)
    
    Shaders.applyCardGlow(function()
        love.graphics.setColor(MenuSystem.titleColor)
        love.graphics.setFont(love.graphics.newFont(64))
        love.graphics.printf(MenuSystem.title, -w/4, -50, w/2, "center")
    end, MenuSystem.titleColor, 0.8)
    
    love.graphics.pop()
    
    -- Draw menu items
    local menu = MenuSystem.menuItems[MenuSystem.currentMenu]
    local itemHeight = 60
    local startY = h/2 - (#menu * itemHeight)/2
    
    for i, item in ipairs(menu) do
        local y = startY + (i-1) * itemHeight
        local isSelected = i == MenuSystem.selectedIndex
        
        -- Draw menu item with card glow effect
        love.graphics.push()
        love.graphics.translate(w/2, y)
        love.graphics.rotate(isSelected and MenuSystem.cardRotation or 0)
        love.graphics.scale(isSelected and MenuSystem.cardScale or 1)
        
        local color = isSelected and MenuSystem.selectedColor or 
                     (MenuSystem.cardHover and MenuSystem.hoverColor or MenuSystem.menuColor)
        
        Shaders.applyCardGlow(function()
            love.graphics.setColor(color)
            love.graphics.setFont(love.graphics.newFont(32))
            
            if item.type == "slider" then
                -- Draw slider
                local sliderWidth = 200
                local sliderHeight = 20
                local sliderX = -sliderWidth/2
                local sliderY = -sliderHeight/2
                
                -- Draw slider background
                love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
                love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth, sliderHeight, 10)
                
                -- Draw slider fill
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth * item.value, sliderHeight, 10)
                
                -- Draw slider handle
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("fill", sliderX + sliderWidth * item.value, sliderY + sliderHeight/2, 15)
                
                -- Draw text
                love.graphics.setColor(color)
                love.graphics.printf(item.text, -w/4, -50, w/2, "center")
            else
                love.graphics.printf(item.text, -w/4, -50, w/2, "center")
            end
        end, color, isSelected and 0.6 or 0.3)
        
        love.graphics.pop()
    end
end

function MenuSystem.keypressed(key)
    local menu = MenuSystem.menuItems[MenuSystem.currentMenu]
    
    if key == "up" then
        MenuSystem.selectedIndex = MenuSystem.selectedIndex - 1
        if MenuSystem.selectedIndex < 1 then
            MenuSystem.selectedIndex = #menu
        end
    elseif key == "down" then
        MenuSystem.selectedIndex = MenuSystem.selectedIndex + 1
        if MenuSystem.selectedIndex > #menu then
            MenuSystem.selectedIndex = 1
        end
    elseif key == "return" then
        local item = menu[MenuSystem.selectedIndex]
        if item.action then
            if item.action == "back" then
                MenuSystem.currentMenu = "main"
                MenuSystem.selectedIndex = 1
            elseif item.action == "start_game" then
                -- Start game logic
            elseif item.action == "settings" then
                MenuSystem.currentMenu = "settings"
                MenuSystem.selectedIndex = 1
            elseif item.action == "credits" then
                MenuSystem.currentMenu = "credits"
                MenuSystem.selectedIndex = 1
            elseif item.action == "exit" then
                love.event.quit()
            end
        end
    elseif key == "left" or key == "right" then
        local item = menu[MenuSystem.selectedIndex]
        if item.type == "slider" then
            local change = (key == "left" and -0.1) or 0.1
            item.value = math.max(item.min, math.min(item.max, item.value + change))
        end
    end
end

function MenuSystem.mousepressed(x, y, button)
    local menu = MenuSystem.menuItems[MenuSystem.currentMenu]
    local itemHeight = 60
    local startY = love.graphics.getHeight()/2 - (#menu * itemHeight)/2
    
    for i, item in ipairs(menu) do
        local itemY = startY + (i-1) * itemHeight
        if y >= itemY - 30 and y <= itemY + 30 then
            MenuSystem.selectedIndex = i
            if button == 1 then
                if item.action then
                    if item.action == "back" then
                        MenuSystem.currentMenu = "main"
                        MenuSystem.selectedIndex = 1
                    elseif item.action == "start_game" then
                        -- Start game logic
                    elseif item.action == "settings" then
                        MenuSystem.currentMenu = "settings"
                        MenuSystem.selectedIndex = 1
                    elseif item.action == "credits" then
                        MenuSystem.currentMenu = "credits"
                        MenuSystem.selectedIndex = 1
                    elseif item.action == "exit" then
                        love.event.quit()
                    end
                end
            end
            break
        end
    end
end

function MenuSystem.mousemoved(x, y)
    local menu = MenuSystem.menuItems[MenuSystem.currentMenu]
    local itemHeight = 60
    local startY = love.graphics.getHeight()/2 - (#menu * itemHeight)/2
    
    MenuSystem.cardHover = false
    for i, item in ipairs(menu) do
        local itemY = startY + (i-1) * itemHeight
        if y >= itemY - 30 and y <= itemY + 30 then
            MenuSystem.cardHover = true
            break
        end
    end
end

return MenuSystem 
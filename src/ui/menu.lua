local Constants = require("utils.constants")
local Player = require("core.player")
local Obstacles = require("core.obstacles")
local Audio = require("core.audio")

local Menu = {
    current = nil,
    screens = {}
}

-- UI Components
local Button = {
    new = function(text, x, y, width, height, callback)
        local button = {
            text = text,
            x = x,
            y = y,
            width = width,
            height = height,
            callback = callback,
            hovered = false,
            clicked = false
        }
        
        -- Add methods to the button instance
        function button:update(mouseX, mouseY, mousePressed)
            self.hovered = mouseX >= self.x and mouseX <= self.x + self.width and
                          mouseY >= self.y and mouseY <= self.y + self.height
            
            if self.hovered and mousePressed then
                self.clicked = true
            elseif not mousePressed then
                if self.clicked and self.hovered then
                    self.callback()
                end
                self.clicked = false
            end
        end
        
        function button:draw()
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            if self.hovered then
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
            end
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(self.text, self.x, self.y + self.height/2 - 10, self.width, "center")
        end
        
        return button
    end
}

-- Menu Screens
Menu.screens.main = {
    buttons = {},
    initialize = function()
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local buttonWidth = 200
        local buttonHeight = 50
        local spacing = 20
        local startY = screenHeight/2 - (buttonHeight + spacing) * 2
        
        Menu.screens.main.buttons = {
            Button.new("New Game", screenWidth/2 - buttonWidth/2, startY, buttonWidth, buttonHeight, function()
                Menu.current = Menu.screens.characterCreation
            end),
            Button.new("Load Game", screenWidth/2 - buttonWidth/2, startY + buttonHeight + spacing, buttonWidth, buttonHeight, function()
                -- TODO: Implement load game
            end),
            Button.new("Settings", screenWidth/2 - buttonWidth/2, startY + (buttonHeight + spacing) * 2, buttonWidth, buttonHeight, function()
                Menu.current = Menu.screens.settings
            end),
            Button.new("Quit", screenWidth/2 - buttonWidth/2, startY + (buttonHeight + spacing) * 3, buttonWidth, buttonHeight, function()
                love.event.quit()
            end)
        }
    end,
    
    update = function(dt)
        local mouseX, mouseY = love.mouse.getPosition()
        local mousePressed = love.mouse.isDown(1)
        
        for _, button in ipairs(Menu.screens.main.buttons) do
            button:update(mouseX, mouseY, mousePressed)
        end
    end,
    
    draw = function()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("RPG Game", 0, 100, love.graphics.getWidth(), "center")
        
        for _, button in ipairs(Menu.screens.main.buttons) do
            button:draw()
        end
    end
}

Menu.screens.characterCreation = {
    buttons = {},
    inputFields = {},
    selectedClass = nil,
    characterName = "",
    
    initialize = function()
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local buttonWidth = 200
        local buttonHeight = 50
        local spacing = 20
        
        Menu.screens.characterCreation.buttons = {
            Button.new("Create", screenWidth/2 - buttonWidth/2, screenHeight - 100, buttonWidth, buttonHeight, function()
                if Menu.screens.characterCreation.selectedClass and Menu.screens.characterCreation.characterName ~= "" then
                    -- TODO: Create character and start game
                    Menu.current = nil
                end
            end),
            Button.new("Back", screenWidth/2 - buttonWidth/2, screenHeight - 50, buttonWidth, buttonHeight, function()
                Menu.current = Menu.screens.main
            end)
        }
    end,
    
    update = function(dt)
        local mouseX, mouseY = love.mouse.getPosition()
        local mousePressed = love.mouse.isDown(1)
        
        for _, button in ipairs(Menu.screens.characterCreation.buttons) do
            button:update(mouseX, mouseY, mousePressed)
        end
    end,
    
    draw = function()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Create Character", 0, 50, love.graphics.getWidth(), "center")
        
        -- Draw class selection
        love.graphics.printf("Select Class:", 0, 150, love.graphics.getWidth(), "center")
        local classes = {"Warrior", "Mage", "Rogue"}
        local buttonWidth = 150
        local buttonHeight = 40
        local spacing = 20
        local startX = love.graphics.getWidth()/2 - (buttonWidth + spacing) * (#classes - 1)/2
        
        for i, class in ipairs(classes) do
            local x = startX + (i-1) * (buttonWidth + spacing)
            local y = 200
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            if Menu.screens.characterCreation.selectedClass == class then
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
            end
            love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(class, x, y + buttonHeight/2 - 10, buttonWidth, "center")
        end
        
        -- Draw name input
        love.graphics.printf("Character Name:", 0, 300, love.graphics.getWidth(), "center")
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 150, 350, 300, 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(Menu.screens.characterCreation.characterName, love.graphics.getWidth()/2 - 150, 360, 300, "center")
        
        for _, button in ipairs(Menu.screens.characterCreation.buttons) do
            button:draw()
        end
    end
}

Menu.screens.settings = {
    buttons = {},
    sliders = {},
    
    initialize = function()
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local buttonWidth = 200
        local buttonHeight = 50
        
        Menu.screens.settings.buttons = {
            Button.new("Back", screenWidth/2 - buttonWidth/2, screenHeight - 100, buttonWidth, buttonHeight, function()
                Menu.current = Menu.screens.main
            end)
        }
    end,
    
    update = function(dt)
        local mouseX, mouseY = love.mouse.getPosition()
        local mousePressed = love.mouse.isDown(1)
        
        for _, button in ipairs(Menu.screens.settings.buttons) do
            button:update(mouseX, mouseY, mousePressed)
        end
    end,
    
    draw = function()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Settings", 0, 50, love.graphics.getWidth(), "center")
        
        for _, button in ipairs(Menu.screens.settings.buttons) do
            button:draw()
        end
    end
}

function Menu.initialize()
    Menu.screens.main.initialize()
    Menu.screens.characterCreation.initialize()
    Menu.screens.settings.initialize()
    Menu.current = Menu.screens.main
end

function Menu.update(dt)
    if Menu.current then
        Menu.current.update(dt)
    end
end

function Menu.draw()
    if Menu.current then
        Menu.current.draw()
    end
end

function Menu.textinput(t)
    if Menu.current == Menu.screens.characterCreation then
        if #Menu.screens.characterCreation.characterName < 20 then
            Menu.screens.characterCreation.characterName = Menu.screens.characterCreation.characterName .. t
        end
    end
end

function Menu.keypressed(key)
    if Menu.current == Menu.screens.characterCreation then
        if key == "backspace" then
            Menu.screens.characterCreation.characterName = Menu.screens.characterCreation.characterName:sub(1, -2)
        end
    end
end

return Menu 
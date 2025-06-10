local Constants = require("utils.constants")

local Obstacles = {
    types = {
        STATIC = "static",
        MOVING = "moving",
        ROTATING = "rotating"
    }
}

function Obstacles.initialize()
    local obstacles = {}
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Add static obstacles
    table.insert(obstacles, {
        x = screenWidth/2 - 25,
        y = screenHeight/2 - 25,
        width = 50,
        height = 50,
        type = Obstacles.types.STATIC,
        color = {0.6, 0.6, 0.7}
    })
    
    -- Add moving obstacles
    table.insert(obstacles, {
        x = screenWidth/2 - 75,
        y = 200,
        width = 150,
        height = 20,
        type = Obstacles.types.MOVING,
        speed = 100,
        startY = 200,
        endY = screenHeight - 220,
        direction = 1,
        color = {0.7, 0.5, 0.6}
    })
    
    -- Add rotating obstacles
    table.insert(obstacles, {
        x = screenWidth/2 - 75,
        y = screenHeight - 220,
        width = 150,
        height = 20,
        type = Obstacles.types.ROTATING,
        rotation = 0,
        rotationSpeed = 1,
        pivotX = screenWidth/2,
        pivotY = screenHeight/2,
        color = {0.5, 0.7, 0.6}
    })

    return obstacles
end

function Obstacles.update(obstacles, dt)
    for _, obstacle in ipairs(obstacles) do
        if obstacle.type == Obstacles.types.MOVING then
            -- Update moving obstacle position
            obstacle.y = obstacle.y + obstacle.speed * obstacle.direction * dt
            
            -- Reverse direction at boundaries
            if obstacle.y <= obstacle.startY or obstacle.y >= obstacle.endY then
                obstacle.direction = -obstacle.direction
            end
        elseif obstacle.type == Obstacles.types.ROTATING then
            -- Update rotating obstacle
            obstacle.rotation = obstacle.rotation + obstacle.rotationSpeed * dt
            
            -- Calculate new position based on rotation
            local radius = 200
            obstacle.x = obstacle.pivotX + math.cos(obstacle.rotation) * radius - obstacle.width/2
            obstacle.y = obstacle.pivotY + math.sin(obstacle.rotation) * radius - obstacle.height/2
        end
    end
end

function Obstacles.draw(obstacles)
    for _, obstacle in ipairs(obstacles) do
        -- Set obstacle color
        love.graphics.setColor(obstacle.color)
        
        -- Draw obstacle with rotation if needed
        if obstacle.type == Obstacles.types.ROTATING then
            love.graphics.push()
            love.graphics.translate(obstacle.x + obstacle.width/2, obstacle.y + obstacle.height/2)
            love.graphics.rotate(obstacle.rotation)
            love.graphics.rectangle("fill", -obstacle.width/2, -obstacle.height/2, obstacle.width, obstacle.height)
            love.graphics.pop()
        else
            love.graphics.rectangle("fill", obstacle.x, obstacle.y, obstacle.width, obstacle.height)
        end
        
        -- Add a subtle border to make obstacles more visible
        love.graphics.setColor(obstacle.color[1] + 0.2, obstacle.color[2] + 0.2, obstacle.color[3] + 0.2)
        if obstacle.type == Obstacles.types.ROTATING then
            love.graphics.push()
            love.graphics.translate(obstacle.x + obstacle.width/2, obstacle.y + obstacle.height/2)
            love.graphics.rotate(obstacle.rotation)
            love.graphics.rectangle("line", -obstacle.width/2, -obstacle.height/2, obstacle.width, obstacle.height)
            love.graphics.pop()
        else
            love.graphics.rectangle("line", obstacle.x, obstacle.y, obstacle.width, obstacle.height)
        end
    end
end

-- Networking stub for future MMORPG
function Obstacles.syncToServer(obstacles)
    -- TODO: Send obstacles state to server
end

function Obstacles.syncFromServer(data)
    -- TODO: Update obstacles state from server data
end

return Obstacles 
local WorldObject = {
    types = {
        BUILDING = {
            name = "Building",
            size = {width = 100, height = 100},
            color = {0.6, 0.4, 0.2}
        },
        TREE = {
            name = "Tree",
            size = {width = 40, height = 60},
            color = {0.2, 0.6, 0.2}
        },
        ROCK = {
            name = "Rock",
            size = {width = 30, height = 30},
            color = {0.5, 0.5, 0.5}
        },
        CHEST = {
            name = "Chest",
            size = {width = 40, height = 30},
            color = {0.8, 0.6, 0.2},
            isOpen = false
        },
        FOUNTAIN = {
            name = "Fountain",
            size = {width = 60, height = 60},
            color = {0.7, 0.7, 0.9},
            radius = 20
        }
    }
}

function WorldObject.new(objectType, x, y)
    local type = WorldObject.types[objectType] or WorldObject.types.BUILDING
    return {
        type = type,
        x = x or 0,
        y = y or 0,
        size = type.size,
        color = type.color,
        state = "default",
        interactionRange = 50,
        isInteracting = false
    }
end

function WorldObject.update(object, dt)
    -- Update object state
    if object.type == WorldObject.types.FOUNTAIN then
        -- Animate fountain water
        object.waterOffset = (object.waterOffset or 0) + dt * 2
        if object.waterOffset > 1 then
            object.waterOffset = 0
        end
    end
end

function WorldObject.draw(object)
    -- Draw object
    love.graphics.setColor(object.color)
    
    if object.type == WorldObject.types.FOUNTAIN then
        -- Draw fountain base
        love.graphics.rectangle("fill", 
            object.x - object.size.width/2,
            object.y - object.size.height/2,
            object.size.width,
            object.size.height
        )
        
        -- Draw water
        love.graphics.setColor(0.3, 0.5, 1, 0.7)
        local waterY = object.y - object.size.height/2 + 
            math.sin(object.waterOffset * math.pi * 2) * 5
        love.graphics.circle("fill", object.x, waterY, object.type.radius)
        
    elseif object.type == WorldObject.types.TREE then
        -- Draw tree trunk
        love.graphics.rectangle("fill",
            object.x - object.size.width/4,
            object.y - object.size.height/2,
            object.size.width/2,
            object.size.height
        )
        
        -- Draw tree top
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.circle("fill", object.x, object.y - object.size.height/2, object.size.width/2)
        
    else
        -- Draw standard object
        love.graphics.rectangle("fill",
            object.x - object.size.width/2,
            object.y - object.size.height/2,
            object.size.width,
            object.size.height
        )
    end
    
    -- Draw interaction indicator if player is in range
    if object.isInteracting then
        love.graphics.setColor(1, 1, 0, 0.3)
        love.graphics.circle("fill", object.x, object.y, object.interactionRange)
    end
end

function WorldObject.interact(object, player)
    if not object.isInteracting then return end
    
    -- Handle different object types
    if object.type == WorldObject.types.CHEST then
        if not object.isOpen then
            object.isOpen = true
            return "chest_open"
        end
    elseif object.type == WorldObject.types.FOUNTAIN then
        return "fountain_drink"
    end
end

function WorldObject.getState(object)
    return {
        x = object.x,
        y = object.y,
        state = object.state,
        isOpen = object.isOpen,
        waterOffset = object.waterOffset
    }
end

function WorldObject.setState(object, state)
    if not state then return end
    object.x = state.x or object.x
    object.y = state.y or object.y
    object.state = state.state or object.state
    object.isOpen = state.isOpen or object.isOpen
    object.waterOffset = state.waterOffset or object.waterOffset
end

return WorldObject 
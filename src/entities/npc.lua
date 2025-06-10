local NPC = {
    types = {
        MERCHANT = {
            name = "Merchant",
            dialog = "Welcome! What can I do for you today?",
            inventory = {},
            interactionRange = 50
        },
        QUEST_GIVER = {
            name = "Quest Giver",
            dialog = "I have a task for you, adventurer.",
            quests = {},
            interactionRange = 50
        },
        GUARD = {
            name = "Guard",
            dialog = "Halt! Who goes there?",
            patrolPath = {},
            interactionRange = 50
        }
    }
}

function NPC.new(npcType, x, y)
    local type = NPC.types[npcType] or NPC.types.MERCHANT
    return {
        type = type,
        x = x or 0,
        y = y or 0,
        size = 32,
        dialog = type.dialog,
        interactionRange = type.interactionRange,
        isInteracting = false,
        state = "idle",
        patrolIndex = 1,
        patrolTimer = 0,
        color = {0.8, 0.8, 0.8}
    }
end

function NPC.update(npc, dt)
    if npc.type == NPC.types.GUARD then
        -- Update patrol behavior
        if #npc.type.patrolPath > 0 then
            npc.patrolTimer = npc.patrolTimer + dt
            if npc.patrolTimer >= 2 then  -- Change direction every 2 seconds
                npc.patrolIndex = (npc.patrolIndex % #npc.type.patrolPath) + 1
                npc.patrolTimer = 0
            end
            
            -- Move towards patrol point
            local target = npc.type.patrolPath[npc.patrolIndex]
            local dx = target.x - npc.x
            local dy = target.y - npc.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist > 5 then
                npc.x = npc.x + (dx / dist) * 50 * dt
                npc.y = npc.y + (dy / dist) * 50 * dt
            end
        end
    end
end

function NPC.draw(npc)
    -- Draw NPC
    love.graphics.setColor(npc.color)
    love.graphics.rectangle("fill", npc.x - npc.size/2, npc.y - npc.size/2, npc.size, npc.size)
    
    -- Draw name
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(npc.type.name, npc.x - npc.size/2, npc.y - npc.size - 20)
    
    -- Draw interaction indicator if player is in range
    if npc.isInteracting then
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.circle("fill", npc.x, npc.y, npc.interactionRange)
    end
end

function NPC.interact(npc, player)
    if not npc.isInteracting then return end
    
    -- Handle different NPC types
    if npc.type == NPC.types.MERCHANT then
        -- Open shop interface
        return "shop"
    elseif npc.type == NPC.types.QUEST_GIVER then
        -- Show available quests
        return "quests"
    elseif npc.type == NPC.types.GUARD then
        -- Show guard dialog
        return "dialog"
    end
end

function NPC.getState(npc)
    return {
        x = npc.x,
        y = npc.y,
        state = npc.state,
        patrolIndex = npc.patrolIndex,
        patrolTimer = npc.patrolTimer
    }
end

function NPC.setState(npc, state)
    if not state then return end
    npc.x = state.x or npc.x
    npc.y = state.y or npc.y
    npc.state = state.state or npc.state
    npc.patrolIndex = state.patrolIndex or npc.patrolIndex
    npc.patrolTimer = state.patrolTimer or npc.patrolTimer
end

return NPC 
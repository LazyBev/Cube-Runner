local NPC = require("entities.npc")
local WorldObject = require("entities.world_object")

local World = {
    currentZone = nil,
    zones = {},
    npcs = {},
    quests = {},
    spawnPoints = {},
    worldObjects = {}
}

-- Zone types
World.ZONE_TYPES = {
    TOWN = "town",
    DUNGEON = "dungeon",
    WILDERNESS = "wilderness",
    INSTANCE = "instance"
}

-- Initialize world zones
function World.initialize()
    -- Create starting town
    World.zones["starting_town"] = {
        name = "Starting Town",
        type = World.ZONE_TYPES.TOWN,
        bounds = {x = 0, y = 0, width = 1000, height = 1000},
        npcs = {
            NPC.new("MERCHANT", 150, 150),
            NPC.new("QUEST_GIVER", 200, 200),
            NPC.new("GUARD", 250, 250)
        },
        spawnPoints = {
            {x = 100, y = 100, name = "Town Square"},
            {x = 200, y = 200, name = "Market"}
        },
        worldObjects = {
            WorldObject.new("BUILDING", 150, 150),
            WorldObject.new("FOUNTAIN", 300, 300)
        }
    }
    
    -- Create wilderness area
    World.zones["wilderness"] = {
        name = "Wilderness",
        type = World.ZONE_TYPES.WILDERNESS,
        bounds = {x = 1000, y = 0, width = 2000, height = 2000},
        npcs = {
            NPC.new("GUARD", 1100, 100)
        },
        spawnPoints = {
            {x = 1100, y = 100, name = "Forest Entrance"},
            {x = 1200, y = 200, name = "River Crossing"}
        },
        worldObjects = {
            WorldObject.new("TREE", 1150, 150),
            WorldObject.new("ROCK", 1250, 250),
            WorldObject.new("CHEST", 1300, 300)
        }
    }
    
    -- Create dungeon
    World.zones["ancient_dungeon"] = {
        name = "Ancient Dungeon",
        type = World.ZONE_TYPES.DUNGEON,
        bounds = {x = 0, y = 1000, width = 800, height = 800},
        npcs = {},
        spawnPoints = {
            {x = 50, y = 1050, name = "Dungeon Entrance"},
            {x = 100, y = 1100, name = "First Chamber"}
        },
        worldObjects = {
            WorldObject.new("CHEST", 150, 1150),
            WorldObject.new("ROCK", 200, 1200)
        }
    }
    
    -- Set starting zone
    World.currentZone = "starting_town"
end

function World.changeZone(zoneName, player)
    if not World.zones[zoneName] then return false end
    
    -- Save current zone state
    if World.currentZone then
        World.saveZoneState(World.currentZone)
    end
    
    -- Load new zone
    World.currentZone = zoneName
    World.loadZoneState(zoneName)
    
    -- Teleport player to spawn point
    local spawnPoint = World.zones[zoneName].spawnPoints[1]
    if spawnPoint then
        player.x = spawnPoint.x
        player.y = spawnPoint.y
    end
    
    return true
end

function World.saveZoneState(zoneName)
    if not World.zones[zoneName] then return end
    
    -- Save NPC states
    for _, npc in pairs(World.zones[zoneName].npcs) do
        npc.state = NPC.getState(npc)
    end
    
    -- Save world object states
    for _, obj in pairs(World.zones[zoneName].worldObjects) do
        obj.state = WorldObject.getState(obj)
    end
end

function World.loadZoneState(zoneName)
    if not World.zones[zoneName] then return end
    
    -- Load NPC states
    for _, npc in pairs(World.zones[zoneName].npcs) do
        if npc.state then
            NPC.setState(npc, npc.state)
        end
    end
    
    -- Load world object states
    for _, obj in pairs(World.zones[zoneName].worldObjects) do
        if obj.state then
            WorldObject.setState(obj, obj.state)
        end
    end
end

function World.update(dt)
    if not World.currentZone then return end
    
    local zone = World.zones[World.currentZone]
    
    -- Update NPCs
    for _, npc in pairs(zone.npcs) do
        NPC.update(npc, dt)
    end
    
    -- Update world objects
    for _, obj in pairs(zone.worldObjects) do
        WorldObject.update(obj, dt)
    end
end

function World.draw()
    if not World.currentZone then return end
    
    local zone = World.zones[World.currentZone]
    
    -- Draw world objects
    for _, obj in pairs(zone.worldObjects) do
        WorldObject.draw(obj)
    end
    
    -- Draw NPCs
    for _, npc in pairs(zone.npcs) do
        NPC.draw(npc)
    end
end

return World 
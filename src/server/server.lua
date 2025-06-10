local socket = require("socket")
local json = require("json")

local Server = {
    clients = {},
    world = {},
    lastUpdate = 0,
    updateRate = 1/20, -- 20 updates per second
    port = 12345
}

-- Message types
Server.MESSAGE_TYPES = {
    CONNECT = "connect",
    DISCONNECT = "disconnect",
    PLAYER_UPDATE = "player_update",
    CHAT = "chat",
    WORLD_STATE = "world_state",
    INVENTORY_UPDATE = "inventory_update",
    QUEST_UPDATE = "quest_update"
}

function Server.initialize()
    -- Create UDP server
    Server.socket = socket.udp()
    Server.socket:settimeout(0)
    Server.socket:setsockname("*", Server.port)
    
    print("Server started on port " .. Server.port)
end

function Server.update()
    -- Receive messages from clients
    while true do
        local data, ip, port = Server.socket:receivefrom()
        if not data then break end
        
        local message = json.decode(data)
        if message then
            Server.handleMessage(message, ip, port)
        end
    end
    
    -- Update world state
    Server.lastUpdate = Server.lastUpdate + 1/60
    if Server.lastUpdate >= Server.updateRate then
        Server.broadcastWorldState()
        Server.lastUpdate = 0
    end
end

function Server.handleMessage(message, ip, port)
    if not message.type then return end
    
    if message.type == Server.MESSAGE_TYPES.CONNECT then
        -- Handle new client connection
        local clientId = ip .. ":" .. port
        Server.clients[clientId] = {
            ip = ip,
            port = port,
            player = message.data
        }
        
        -- Send current world state to new client
        Server.sendMessage(clientId, {
            type = Server.MESSAGE_TYPES.WORLD_STATE,
            data = {
                players = Server.world.players,
                npcs = Server.world.npcs,
                worldObjects = Server.world.worldObjects
            }
        })
        
        -- Notify other clients about new player
        Server.broadcastMessage({
            type = Server.MESSAGE_TYPES.PLAYER_UPDATE,
            data = message.data
        }, clientId)
        
    elseif message.type == Server.MESSAGE_TYPES.DISCONNECT then
        -- Handle client disconnection
        local clientId = ip .. ":" .. port
        if Server.clients[clientId] then
            -- Notify other clients about player leaving
            Server.broadcastMessage({
                type = Server.MESSAGE_TYPES.PLAYER_UPDATE,
                data = {
                    playerId = message.data.playerId,
                    disconnected = true
                }
            }, clientId)
            
            -- Remove client
            Server.clients[clientId] = nil
        end
        
    elseif message.type == Server.MESSAGE_TYPES.PLAYER_UPDATE then
        -- Update player state
        local clientId = ip .. ":" .. port
        if Server.clients[clientId] then
            Server.clients[clientId].player = message.data
            
            -- Broadcast player update to other clients
            Server.broadcastMessage({
                type = Server.MESSAGE_TYPES.PLAYER_UPDATE,
                data = message.data
            }, clientId)
        end
        
    elseif message.type == Server.MESSAGE_TYPES.CHAT then
        -- Broadcast chat message to all clients
        Server.broadcastMessage({
            type = Server.MESSAGE_TYPES.CHAT,
            data = message.data
        })
    end
end

function Server.sendMessage(clientId, message)
    local client = Server.clients[clientId]
    if not client then return end
    
    local data = json.encode(message)
    Server.socket:sendto(data, client.ip, client.port)
end

function Server.broadcastMessage(message, excludeClientId)
    for clientId, client in pairs(Server.clients) do
        if clientId ~= excludeClientId then
            Server.sendMessage(clientId, message)
        end
    end
end

function Server.broadcastWorldState()
    local worldState = {
        type = Server.MESSAGE_TYPES.WORLD_STATE,
        data = {
            players = {},
            npcs = Server.world.npcs,
            worldObjects = Server.world.worldObjects
        }
    }
    
    -- Collect all player states
    for _, client in pairs(Server.clients) do
        table.insert(worldState.data.players, client.player)
    end
    
    -- Broadcast to all clients
    Server.broadcastMessage(worldState)
end

-- Start server
if arg[1] == "server" then
    Server.initialize()
    
    while true do
        Server.update()
        socket.sleep(1/60)
    end
end

return Server 
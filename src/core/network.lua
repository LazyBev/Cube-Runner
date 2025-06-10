local Network = {
    server = nil,
    client = nil,
    players = {},
    connected = false,
    playerId = nil,
    lastUpdate = 0,
    updateRate = 1/20, -- 20 updates per second
}

-- Network message types
Network.MESSAGE_TYPES = {
    CONNECT = "connect",
    DISCONNECT = "disconnect",
    PLAYER_UPDATE = "player_update",
    CHAT = "chat",
    WORLD_STATE = "world_state",
    INVENTORY_UPDATE = "inventory_update",
    QUEST_UPDATE = "quest_update"
}

-- Generate a unique player ID
function Network.generatePlayerId()
    local id = ""
    for i = 1, 8 do
        id = id .. string.format("%x", math.random(0, 15))
    end
    return id
end

function Network.initialize()
    -- Generate player ID
    Network.playerId = Network.generatePlayerId()
    
    -- Initialize UDP socket
    Network.client = love.thread.newThread([[
        local socket = require("socket")
        local udp = socket.udp()
        udp:settimeout(0)
        
        while true do
            local data, ip, port = udp:receivefrom()
            if data then
                love.thread.getChannel("network"):push({
                    data = data,
                    ip = ip,
                    port = port
                })
            end
            socket.sleep(0.001)  -- Use socket.sleep instead of love.timer.sleep
        end
    ]])
    
    Network.client:start()
end

function Network.connect(serverAddress, serverPort)
    if Network.connected then return end
    
    -- Create UDP socket for client
    Network.client = love.thread.newThread([[
        local socket = require("socket")
        local udp = socket.udp()
        udp:settimeout(0)
        udp:setpeername("]] .. serverAddress .. [[", ]] .. serverPort .. [[)
        
        while true do
            local data, ip, port = udp:receivefrom()
            if data then
                love.thread.getChannel("network"):push({
                    data = data,
                    ip = ip,
                    port = port
                })
            end
            socket.sleep(0.001)  -- Use socket.sleep instead of love.timer.sleep
        end
    ]])
    
    Network.client:start()
    Network.connected = true
    
    -- Send initial connection message
    Network.sendMessage(Network.MESSAGE_TYPES.CONNECT, {
        playerId = Network.playerId,
        position = {x = 0, y = 0},
        class = "warrior"
    })
end

function Network.disconnect()
    if not Network.connected then return end
    
    Network.sendMessage(Network.MESSAGE_TYPES.DISCONNECT, {
        playerId = Network.playerId
    })
    
    Network.client:stop()
    Network.connected = false
    Network.players = {}
end

function Network.sendMessage(messageType, data)
    if not Network.connected then return end
    
    local message = {
        type = messageType,
        data = data,
        timestamp = love.timer.getTime()
    }
    
    Network.client:getChannel("send"):push(love.data.encode("string", "json", message))
end

function Network.update(dt)
    if not Network.connected then return end
    
    -- Process received messages
    local message = Network.client:getChannel("network"):pop()
    while message do
        local decoded = love.data.decode("string", "json", message.data)
        Network.handleMessage(decoded)
        message = Network.client:getChannel("network"):pop()
    end
    
    -- Send periodic updates
    Network.lastUpdate = Network.lastUpdate + dt
    if Network.lastUpdate >= Network.updateRate then
        Network.sendPlayerUpdate()
        Network.lastUpdate = 0
    end
end

function Network.handleMessage(message)
    if not message or not message.type then return end
    
    if message.type == Network.MESSAGE_TYPES.PLAYER_UPDATE then
        Network.players[message.data.playerId] = message.data
    elseif message.type == Network.MESSAGE_TYPES.WORLD_STATE then
        -- Update world state (other players, NPCs, etc.)
        Network.players = message.data.players
    elseif message.type == Network.MESSAGE_TYPES.CHAT then
        -- Handle chat messages
        love.event.push("chat_message", message.data)
    end
end

function Network.sendPlayerUpdate()
    if not Network.playerId then return end
    
    Network.sendMessage(Network.MESSAGE_TYPES.PLAYER_UPDATE, {
        playerId = Network.playerId,
        position = Network.players[Network.playerId].position,
        health = Network.players[Network.playerId].health,
        class = Network.players[Network.playerId].class
    })
end

return Network 
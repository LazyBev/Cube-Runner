local Audio = {
    sounds = {},
    music = {},
    currentMusic = nil,
    volume = {
        master = 1.0,
        sfx = 0.7,
        music = 0.5
    },
    listeners = {},
    enabled = true,
    fadeState = nil  -- Track current fade state
}

function Audio.initialize()
    -- Enable audio system
    love.audio.setVolume(Audio.volume.master)
    
    -- Try to load sounds, but don't fail if files are missing
    local soundFiles = {
        dash = "assets/sounds/dash.mp3",
        hit = "assets/sounds/hit.mp3",
        ability = "assets/sounds/ability.mp3",
        menuSelect = "assets/sounds/menu_select.mp3",
        menuMove = "assets/sounds/menu_move.mp3",
        win = "assets/sounds/win.mp3"
    }
    
    for name, path in pairs(soundFiles) do
        local success, source = pcall(function()
            local file = io.open(path, "r")
            if not file then
                error("File does not exist: " .. path)
            end
            file:close()
            return love.audio.newSource(path, "static")
        end)
        
        if success then
            Audio.sounds[name] = source
            source:setVolume(Audio.volume.sfx)
            print("Successfully loaded sound: " .. name)
        else
            print("Error loading sound file: " .. path)
            print("Error details: " .. tostring(source))
            Audio.sounds[name] = nil
        end
    end
    
    -- Try to load music, but don't fail if files are missing
    local musicFiles = {
        menu = "assets/music/menu.ogg",
        gameplay = "assets/music/gameplay.ogg",
        victory = "assets/music/victory.ogg"
    }
    
    for name, path in pairs(musicFiles) do
        local success, source = pcall(function()
            local file = io.open(path, "r")
            if not file then
                error("File does not exist: " .. path)
            end
            file:close()
            return love.audio.newSource(path, "stream")
        end)
        
        if success then
            Audio.music[name] = source
            source:setVolume(Audio.volume.music)
            source:setLooping(true)
            print("Successfully loaded music: " .. name)
        else
            print("Error loading music file: " .. path)
            print("Error details: " .. tostring(source))
            Audio.music[name] = nil
        end
    end
    
    -- Check if any audio files were loaded successfully
    local soundCount = 0
    local musicCount = 0
    for _ in pairs(Audio.sounds) do soundCount = soundCount + 1 end
    for _ in pairs(Audio.music) do musicCount = musicCount + 1 end
    
    if soundCount == 0 and musicCount == 0 then
        print("Warning: No audio files could be loaded. Audio system disabled.")
        Audio.enabled = false
    else
        print(string.format("Audio system initialized with %d sounds and %d music tracks", soundCount, musicCount))
    end
end

function Audio.update(dt, players)
    if not Audio.enabled then return end
    
    -- Update 3D audio positioning
    for _, player in ipairs(players) do
        if player.soundSource then
            local x, y = player.x, player.y
            local screenX, screenY = love.graphics.getWidth()/2, love.graphics.getHeight()/2
            local dx, dy = x - screenX, y - screenY
            local distance = math.sqrt(dx*dx + dy*dy)
            local maxDistance = math.max(screenX, screenY)
            
            -- Calculate pan and volume based on position
            local pan = dx / maxDistance
            local volume = math.max(0, 1 - (distance / maxDistance))
            
            player.soundSource:setPan(pan)
            player.soundSource:setVolume(volume * Audio.volume.sfx)
        end
    end

    -- Handle music fading
    if Audio.fadeState then
        Audio.fadeState.timer = Audio.fadeState.timer + dt
        
        if Audio.fadeState.timer >= Audio.fadeState.duration then
            -- Fade complete
            if Audio.fadeState.type == "out" then
                Audio.fadeState.source:stop()
            end
            Audio.fadeState = nil
        else
            local progress = Audio.fadeState.timer / Audio.fadeState.duration
            if Audio.fadeState.type == "out" then
                Audio.fadeState.source:setVolume(Audio.fadeState.startVolume * (1 - progress))
            else -- fade in
                Audio.fadeState.source:setVolume(Audio.volume.music * progress)
            end
        end
    end
end

function Audio.playSound(soundName, x, y)
    if not Audio.enabled or not Audio.sounds[soundName] then return end
    
    local sound = Audio.sounds[soundName]
    -- Create a new source for 3D positioning
    local source = sound:clone()
    if x and y then
        local screenX, screenY = love.graphics.getWidth()/2, love.graphics.getHeight()/2
        local dx, dy = x - screenX, y - screenY
        local distance = math.sqrt(dx*dx + dy*dy)
        local maxDistance = math.max(screenX, screenY)
        
        source:setPan(dx / maxDistance)
        source:setVolume(math.max(0, 1 - (distance / maxDistance)) * Audio.volume.sfx)
    end
    
    source:play()
    return source
end

function Audio.playMusic(musicName, fadeTime)
    if not Audio.enabled or not Audio.music[musicName] then return end
    
    fadeTime = fadeTime or 1.0 -- Default fade time of 1 second
    
    if Audio.currentMusic then
        -- Fade out current music
        local current = Audio.currentMusic
        local target = Audio.music[musicName]
        
        if current ~= target then
            Audio.fadeState = {
                type = "out",
                source = current,
                startVolume = current:getVolume(),
                timer = 0,
                duration = fadeTime
            }
        end
    end
    
    -- Fade in new music
    local music = Audio.music[musicName]
    if music then
        music:setVolume(0)
        music:play()
        
        Audio.fadeState = {
            type = "in",
            source = music,
            timer = 0,
            duration = fadeTime
        }
        
        Audio.currentMusic = music
    end
end

function Audio.setVolume(category, volume)
    if not Audio.enabled then return end
    
    if category == "master" then
        Audio.volume.master = volume
        love.audio.setVolume(volume)
    elseif category == "music" then
        Audio.volume.music = volume
        for _, music in pairs(Audio.music) do
            music:setVolume(volume)
        end
    elseif category == "sfx" then
        Audio.volume.sfx = volume
        for _, sound in pairs(Audio.sounds) do
            sound:setVolume(volume)
        end
    end
end

function Audio.addListener(x, y)
    if not Audio.enabled then return end
    table.insert(Audio.listeners, {x = x, y = y})
end

function Audio.removeListener(index)
    if not Audio.enabled then return end
    table.remove(Audio.listeners, index)
end

function Audio.load()
    -- Create default audio sources
    local function createDefaultSource()
        local success, source = pcall(function()
            local buffer = love.sound.newSoundData(1, 44100, 16, 1)
            local source = love.audio.newSource(buffer)
            if source then
                source:setVolume(0)
            end
            return source
        end)
        
        if not success or not source then
            -- If we can't create a proper source, return a dummy object
            return {
                setVolume = function() end,
                stop = function() end,
                play = function() end
            }
        end
        
        return source
    end

    -- Initialize all sound effects
    local soundFiles = {
        menuMove = "assets/sounds/menu_move.mp3",
        menuSelect = "assets/sounds/menu_select.mp3",
        menuBack = "assets/sounds/menu_back.mp3",
        dash = "assets/sounds/dash.mp3",
        ability = "assets/sounds/ability.mp3",
        hit = "assets/sounds/hit.mp3",
        win = "assets/sounds/win.mp3"
    }

    for name, path in pairs(soundFiles) do
        local success, source = pcall(love.audio.newSource, path, "static")
        Audio.sounds[name] = success and source or createDefaultSource()
    end
    
    -- Initialize all music
    local musicFiles = {
        menu = "assets/music/menu.ogg",
        game = "assets/music/game.ogg"
    }

    for name, path in pairs(musicFiles) do
        local success, source = pcall(love.audio.newSource, path, "stream")
        Audio.music[name] = success and source or createDefaultSource()
    end
    
    -- Set initial volumes after ensuring all sources are valid
    for name, sound in pairs(Audio.sounds) do
        if sound and type(sound.setVolume) == "function" then
            pcall(sound.setVolume, sound, Audio.volume.sfx * Audio.volume.master)
        end
    end
    
    for name, music in pairs(Audio.music) do
        if music and type(music.setVolume) == "function" then
            pcall(music.setVolume, music, Audio.volume.music * Audio.volume.master)
        end
    end
end

function Audio.playSound(name)
    if Audio.sounds[name] and type(Audio.sounds[name].play) == "function" then
        pcall(function()
            Audio.sounds[name]:stop()
            Audio.sounds[name]:play()
        end)
    end
end

function Audio.playMusic(name)
    if Audio.music[name] and type(Audio.music[name].play) == "function" then
        pcall(function()
            -- Stop all other music
            for _, music in pairs(Audio.music) do
                if music and type(music.stop) == "function" then
                    music:stop()
                end
            end
            Audio.music[name]:play()
        end)
    end
end

function Audio.stopMusic()
    for _, music in pairs(Audio.music) do
        if music and type(music.stop) == "function" then
            pcall(music.stop, music)
        end
    end
end

function Audio.setVolume(volumeType, volume)
    if volumeType == "master" then
        Audio.volume.master = volume
        -- Update all volumes to reflect new master volume
        for _, sound in pairs(Audio.sounds) do
            if sound and type(sound.setVolume) == "function" then
                pcall(sound.setVolume, sound, Audio.volume.sfx * volume)
            end
        end
        for _, music in pairs(Audio.music) do
            if music and type(music.setVolume) == "function" then
                pcall(music.setVolume, music, Audio.volume.music * volume)
            end
        end
    elseif volumeType == "sound" then
        Audio.volume.sfx = volume
        for _, sound in pairs(Audio.sounds) do
            if sound and type(sound.setVolume) == "function" then
                pcall(sound.setVolume, sound, volume * Audio.volume.master)
            end
        end
    elseif volumeType == "music" then
        Audio.volume.music = volume
        for _, music in pairs(Audio.music) do
            if music and type(music.setVolume) == "function" then
                pcall(music.setVolume, music, volume * Audio.volume.master)
            end
        end
    end
end

function Audio.getVolume(volumeType)
    if volumeType == "master" then
        return Audio.volume.master
    elseif volumeType == "sound" then
        return Audio.volume.sfx
    elseif volumeType == "music" then
        return Audio.volume.music
    end
    return 0
end

-- Networking stubs for MMORPG
function Audio.sendSoundEventToServer(event, params)
    -- TODO: Send sound event to server for global SFX
end

function Audio.receiveSoundEventFromServer(event, params)
    -- TODO: Play sound event received from server
end

return Audio 
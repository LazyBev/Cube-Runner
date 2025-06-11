local AudioManager = {}

-- Audio sources
local sounds = {
    hit = nil,
    menuSelect = nil,
    ability = nil,
    win = nil,
    dash = nil,
    menuMove = nil
}

local music = {
    menu = nil,
    gameplay = nil,
    victory = nil
}

local currentMusic = nil

function AudioManager.init()
    -- Load sound effects
    sounds.hit = love.audio.newSource("assets/sounds/hit.mp3", "static")
    sounds.menuSelect = love.audio.newSource("assets/sounds/menu_select.mp3", "static")
    sounds.ability = love.audio.newSource("assets/sounds/ability.mp3", "static")
    sounds.win = love.audio.newSource("assets/sounds/win.mp3", "static")
    sounds.dash = love.audio.newSource("assets/sounds/dash.mp3", "static")
    sounds.menuMove = love.audio.newSource("assets/sounds/menu_move.mp3", "static")
    
    -- Load music
    music.menu = love.audio.newSource("assets/music/menu.ogg", "stream")
    music.gameplay = love.audio.newSource("assets/music/gameplay.ogg", "stream")
    music.victory = love.audio.newSource("assets/music/victory.ogg", "stream")
    
    -- Set music to loop
    music.menu:setLooping(true)
    music.gameplay:setLooping(true)
    music.victory:setLooping(true)
    
    -- Set volumes
    love.audio.setVolume(0.7) -- Master volume
    for _, sound in pairs(sounds) do
        sound:setVolume(0.5)
    end
    for _, track in pairs(music) do
        track:setVolume(0.3)
    end
end

function AudioManager.playSound(soundName)
    if sounds[soundName] then
        sounds[soundName]:stop()
        sounds[soundName]:play()
    end
end

function AudioManager.playMusic(musicName)
    if currentMusic then
        currentMusic:stop()
    end
    if music[musicName] then
        music[musicName]:play()
        currentMusic = music[musicName]
    end
end

function AudioManager.stopMusic()
    if currentMusic then
        currentMusic:stop()
        currentMusic = nil
    end
end

function AudioManager.setVolume(volume)
    love.audio.setVolume(volume)
end

function AudioManager.setMusicVolume(volume)
    for _, track in pairs(music) do
        track:setVolume(volume)
    end
end

function AudioManager.setSoundVolume(volume)
    for _, sound in pairs(sounds) do
        sound:setVolume(volume)
    end
end

return AudioManager 
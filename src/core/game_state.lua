local GameState = {
    current = nil,
    previous = nil,
    states = {
        MAIN_MENU = "main_menu",
        CHARACTER_CREATION = "character_creation",
        GAME = "game",
        INVENTORY = "inventory",
        QUEST_LOG = "quest_log",
        SKILL_TREE = "skill_tree",
        MAP = "map",
        SETTINGS = "settings",
        PAUSE = "pause"
    }
}

function GameState.initialize()
    GameState.current = GameState.states.MAIN_MENU
    GameState.previous = nil
end

function GameState.change(newState)
    if GameState.current then
        GameState.previous = GameState.current
    end
    GameState.current = newState
end

function GameState.isInState(state)
    return GameState.current == state
end

function GameState.getCurrent()
    return GameState.current
end

function GameState.getPrevious()
    return GameState.previous
end

return GameState 
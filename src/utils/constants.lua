local Constants = {
    -- Game states
    STATES = {
        MENU = "menu",
        PLAYING = "playing",
        WIN = "win"
    },
    
    -- Game modes
    MODES = {
        REGULAR = "regular",
        ICEY = "icey"
    },
    
    -- Menu options
    MENU_OPTIONS = {
        "Start Game",
        "Options",
        "Customize",
        "Exit"
    },
    
    -- RPG Items
    ITEMS = {
        { name = "Health Potion", type = "consumable", effect = "heal", value = 50 },
        { name = "Iron Sword", type = "weapon", power = 5 },
        { name = "Leather Armor", type = "armor", defense = 3 }
    },
    -- RPG Abilities
    ABILITIES = {
        { name = "Berserk", desc = "Double power for 5s", cooldown = 10 },
        { name = "Fireball", desc = "Shoot a fireball", cooldown = 8 },
        { name = "Dash", desc = "Quickly dash forward", cooldown = 5 }
    },
    -- Options menu
    OPTIONS_MENU = {
        "Sound Volume",
        "Music Volume",
        "Fullscreen",
        "Back"
    },
    
    -- Customize menu
    CUSTOMIZE_OPTIONS = {
        "Player Name",
        "Color",
        "Keybinds",
        "Back"
    },
    
    -- Color presets
    COLOR_PRESETS = {
        {name = "Red", color = {1, 0, 0}},
        {name = "Green", color = {0, 1, 0}},
        {name = "Blue", color = {0, 0, 1}},
        {name = "Yellow", color = {1, 1, 0}},
        {name = "Purple", color = {1, 0, 1}},
        {name = "Cyan", color = {0, 1, 1}},
        {name = "Orange", color = {1, 0.5, 0}},
        {name = "Pink", color = {1, 0.4, 0.7}}
    },
    
    -- Player classes
    PLAYER_CLASSES = {
        {
            name = "Warrior",
            health = 150,
            speed = 200,
            dashCooldown = 1.5,
            color = {0.8, 0.2, 0.2},  -- Red
            ability = {
                name = "Berserk",
                description = "Increases speed and damage for 5 seconds",
                cooldown = 10,
                duration = 5,
                uses = 3
            }
        },
        {
            name = "Mage",
            health = 100,
            speed = 180,
            dashCooldown = 1.0,
            color = {0.2, 0.2, 0.8},  -- Blue
            ability = {
                name = "Time Warp",
                description = "Slows down time for 3 seconds",
                cooldown = 15,
                duration = 3,
                uses = 2
            }
        },
        {
            name = "Rogue",
            health = 120,
            speed = 250,
            dashCooldown = 0.8,
            color = {0.2, 0.8, 0.2},  -- Green
            ability = {
                name = "Shadow Step",
                description = "Teleports to target location",
                cooldown = 8,
                duration = 0,
                uses = 4
            }
        },
        {
            name = "Tank",
            health = 200,
            speed = 150,
            dashCooldown = 2.0,
            color = {0.8, 0.8, 0.2},  -- Yellow
            ability = {
                name = "Shield Wall",
                description = "Reduces damage taken by 50% for 4 seconds",
                cooldown = 12,
                duration = 4,
                uses = 2
            }
        }
    }
}

return Constants 
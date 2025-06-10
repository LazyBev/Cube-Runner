local Character = {
    classes = {
        WARRIOR = {
            name = "Warrior",
            description = "A master of combat and physical prowess",
            baseStats = {
                health = 100,
                mana = 50,
                strength = 10,
                dexterity = 8,
                intelligence = 5,
                vitality = 10
            },
            skills = {
                "Slash",
                "Shield Block",
                "Battle Cry"
            }
        },
        MAGE = {
            name = "Mage",
            description = "Wielder of arcane magic and elemental forces",
            baseStats = {
                health = 70,
                mana = 100,
                strength = 5,
                dexterity = 6,
                intelligence = 12,
                vitality = 7
            },
            skills = {
                "Fireball",
                "Ice Shield",
                "Arcane Bolt"
            }
        },
        ROGUE = {
            name = "Rogue",
            description = "Swift and deadly, master of stealth",
            baseStats = {
                health = 80,
                mana = 60,
                strength = 7,
                dexterity = 12,
                intelligence = 8,
                vitality = 8
            },
            skills = {
                "Backstab",
                "Stealth",
                "Poison Strike"
            }
        }
    }
}

function Character.new(name, class)
    local character = {
        name = name,
        class = class,
        level = 1,
        experience = 0,
        experienceToNextLevel = 100,
        stats = {},
        skills = {},
        inventory = {},
        equipment = {
            weapon = nil,
            armor = nil,
            accessory = nil
        },
        quests = {
            active = {},
            completed = {}
        }
    }
    
    -- Initialize stats based on class
    for stat, value in pairs(Character.classes[class].baseStats) do
        character.stats[stat] = value
    end
    
    -- Initialize skills based on class
    for _, skillName in ipairs(Character.classes[class].skills) do
        character.skills[skillName] = {
            level = 1,
            experience = 0
        }
    end
    
    return character
end

function Character:gainExperience(amount)
    self.experience = self.experience + amount
    while self.experience >= self.experienceToNextLevel do
        self:levelUp()
    end
end

function Character:levelUp()
    self.level = self.level + 1
    self.experience = self.experience - self.experienceToNextLevel
    self.experienceToNextLevel = math.floor(self.experienceToNextLevel * 1.5)
    
    -- Increase stats
    for stat, value in pairs(self.stats) do
        if stat ~= "health" and stat ~= "mana" then
            self.stats[stat] = value + 1
        end
    end
    
    -- Increase health and mana
    self.stats.health = self.stats.health + 10
    self.stats.mana = self.stats.mana + 5
end

function Character:equipItem(item, slot)
    if self.equipment[slot] then
        self:unequipItem(slot)
    end
    self.equipment[slot] = item
    self:updateStats()
end

function Character:unequipItem(slot)
    if self.equipment[slot] then
        table.insert(self.inventory, self.equipment[slot])
        self.equipment[slot] = nil
        self:updateStats()
    end
end

function Character:updateStats()
    -- Reset to base stats
    for stat, value in pairs(Character.classes[self.class].baseStats) do
        self.stats[stat] = value
    end
    
    -- Apply equipment bonuses
    for _, item in pairs(self.equipment) do
        if item and item.stats then
            for stat, bonus in pairs(item.stats) do
                self.stats[stat] = self.stats[stat] + bonus
            end
        end
    end
end

function Character:addQuest(quest)
    table.insert(self.quests.active, quest)
end

function Character:completeQuest(questId)
    for i, quest in ipairs(self.quests.active) do
        if quest.id == questId then
            table.remove(self.quests.active, i)
            table.insert(self.quests.completed, quest)
            self:gainExperience(quest.experienceReward)
            break
        end
    end
end

return Character 
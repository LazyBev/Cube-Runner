local Quest = {
    types = {
        KILL = "kill",
        COLLECT = "collect",
        EXPLORE = "explore",
        ESCORT = "escort",
        TALK = "talk"
    }
}

function Quest.new(id, title, description, type, objectives, rewards)
    local quest = {
        id = id,
        title = title,
        description = description,
        type = type,
        objectives = objectives,
        rewards = rewards,
        status = "active",
        progress = {},
        completed = false
    }
    
    -- Initialize progress for each objective
    for _, objective in ipairs(objectives) do
        quest.progress[objective.id] = {
            current = 0,
            required = objective.required,
            completed = false
        }
    end
    
    return quest
end

function Quest:updateProgress(objectiveId, amount)
    if self.progress[objectiveId] and not self.progress[objectiveId].completed then
        self.progress[objectiveId].current = self.progress[objectiveId].current + amount
        if self.progress[objectiveId].current >= self.progress[objectiveId].required then
            self.progress[objectiveId].completed = true
            self:checkCompletion()
        end
    end
end

function Quest:checkCompletion()
    for _, progress in pairs(self.progress) do
        if not progress.completed then
            return false
        end
    end
    self.completed = true
    self.status = "completed"
    return true
end

function Quest:getProgress()
    local total = 0
    local completed = 0
    for _, progress in pairs(self.progress) do
        total = total + 1
        if progress.completed then
            completed = completed + 1
        end
    end
    return completed / total
end

-- Example quest definitions
Quest.templates = {
    {
        id = "quest_001",
        title = "Rat Infestation",
        description = "Clear the rats from the town's storage",
        type = Quest.types.KILL,
        objectives = {
            {
                id = "kill_rats",
                description = "Kill 10 rats",
                required = 10
            }
        },
        rewards = {
            experience = 100,
            gold = 50,
            items = {"rat_tail"}
        }
    },
    {
        id = "quest_002",
        title = "Herb Gathering",
        description = "Collect healing herbs for the town's healer",
        type = Quest.types.COLLECT,
        objectives = {
            {
                id = "collect_herbs",
                description = "Collect 5 healing herbs",
                required = 5
            }
        },
        rewards = {
            experience = 150,
            gold = 75,
            items = {"healing_potion"}
        }
    },
    {
        id = "quest_003",
        title = "Ancient Ruins",
        description = "Explore the ancient ruins and find the lost artifact",
        type = Quest.types.EXPLORE,
        objectives = {
            {
                id = "explore_ruins",
                description = "Explore the ruins",
                required = 1
            },
            {
                id = "find_artifact",
                description = "Find the lost artifact",
                required = 1
            }
        },
        rewards = {
            experience = 300,
            gold = 200,
            items = {"ancient_artifact"}
        }
    }
}

return Quest 
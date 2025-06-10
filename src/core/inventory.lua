local Inventory = {
    maxSlots = 20,
    itemTypes = {
        WEAPON = "weapon",
        ARMOR = "armor",
        ACCESSORY = "accessory",
        CONSUMABLE = "consumable",
        MATERIAL = "material",
        QUEST = "quest"
    }
}

function Inventory.new()
    local inventory = {
        slots = {},
        equipment = {
            weapon = nil,
            armor = nil,
            accessory = nil
        },
        gold = 0
    }
    
    -- Initialize empty slots
    for i = 1, Inventory.maxSlots do
        inventory.slots[i] = nil
    end
    
    return inventory
end

function Inventory:addItem(item, quantity)
    quantity = quantity or 1
    
    -- Check if item is stackable and already exists in inventory
    if item.stackable then
        for _, slot in ipairs(self.slots) do
            if slot and slot.id == item.id and slot.quantity < slot.maxStack then
                local spaceLeft = slot.maxStack - slot.quantity
                local amountToAdd = math.min(quantity, spaceLeft)
                slot.quantity = slot.quantity + amountToAdd
                quantity = quantity - amountToAdd
                if quantity <= 0 then
                    return true
                end
            end
        end
    end
    
    -- Find empty slot for remaining items
    while quantity > 0 do
        local emptySlot = self:findEmptySlot()
        if not emptySlot then
            return false -- Inventory is full
        end
        
        local amountToAdd = math.min(quantity, item.maxStack or 1)
        self.slots[emptySlot] = {
            id = item.id,
            name = item.name,
            type = item.type,
            description = item.description,
            quantity = amountToAdd,
            maxStack = item.maxStack or 1,
            stats = item.stats,
            value = item.value
        }
        quantity = quantity - amountToAdd
    end
    
    return true
end

function Inventory:removeItem(itemId, quantity)
    quantity = quantity or 1
    local remaining = quantity
    
    for i, slot in ipairs(self.slots) do
        if slot and slot.id == itemId then
            if slot.quantity <= remaining then
                remaining = remaining - slot.quantity
                self.slots[i] = nil
                if remaining <= 0 then
                    return true
                end
            else
                slot.quantity = slot.quantity - remaining
                return true
            end
        end
    end
    
    return false
end

function Inventory:findEmptySlot()
    for i, slot in ipairs(self.slots) do
        if not slot then
            return i
        end
    end
    return nil
end

function Inventory:equipItem(slotIndex)
    local item = self.slots[slotIndex]
    if not item then return false end
    
    -- Check if item is equippable
    if not (item.type == Inventory.itemTypes.WEAPON or 
            item.type == Inventory.itemTypes.ARMOR or 
            item.type == Inventory.itemTypes.ACCESSORY) then
        return false
    end
    
    -- Unequip current item in that slot
    if self.equipment[item.type] then
        self:addItem(self.equipment[item.type])
    end
    
    -- Equip new item
    self.equipment[item.type] = item
    self.slots[slotIndex] = nil
    
    return true
end

function Inventory:unequipItem(slotType)
    if not self.equipment[slotType] then return false end
    
    local item = self.equipment[slotType]
    if self:addItem(item) then
        self.equipment[slotType] = nil
        return true
    end
    
    return false
end

function Inventory:getItemCount(itemId)
    local count = 0
    for _, slot in ipairs(self.slots) do
        if slot and slot.id == itemId then
            count = count + slot.quantity
        end
    end
    return count
end

function Inventory:addGold(amount)
    self.gold = self.gold + amount
end

function Inventory:removeGold(amount)
    if self.gold >= amount then
        self.gold = self.gold - amount
        return true
    end
    return false
end

-- Example item definitions
Inventory.items = {
    {
        id = "sword_001",
        name = "Iron Sword",
        type = Inventory.itemTypes.WEAPON,
        description = "A basic iron sword",
        value = 100,
        stats = {
            damage = 10,
            strength = 2
        }
    },
    {
        id = "armor_001",
        name = "Leather Armor",
        type = Inventory.itemTypes.ARMOR,
        description = "Basic leather protection",
        value = 75,
        stats = {
            defense = 5,
            vitality = 1
        }
    },
    {
        id = "potion_001",
        name = "Health Potion",
        type = Inventory.itemTypes.CONSUMABLE,
        description = "Restores 50 health",
        value = 25,
        stackable = true,
        maxStack = 10,
        use = function(character)
            character.stats.health = math.min(character.stats.health + 50, character.stats.maxHealth)
        end
    }
}

return Inventory 
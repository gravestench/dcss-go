local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local item_classes = require("constants.item_classes")

local potions = {}
local registered = {}

-- The potion registry validates item kinds before binding them to effect handlers.
-- Example: potions.register("POT_HEAL_WOUNDS", healing_effect) requires can_quaff and apply.
function potions.register(id, effect)
    local definition = catalog.get(categories.ITEMS, id)

    if definition.class ~= item_classes.POTIONS then
        error("potion effect " .. tostring(id) .. " is not a potion item")
    end

    if type(effect) ~= "table" or
        type(effect.can_quaff) ~= "function" or
        type(effect.apply) ~= "function" then
        error("potion effect " .. id .. " needs can_quaff and apply")
    end

    if registered[id] then
        error("duplicate potion effect " .. id)
    end

    registered[id] = effect
end

-- The command path gets only previously validated handlers from the registry.
function potions.get(id)
    return registered[id]
end

-- Fail startup when an active potion lacks a usable effect handler.
function potions.validate()
    for _, definition in ipairs(catalog.all(categories.ITEMS)) do
        if definition.class == item_classes.POTIONS and
            not definition.explicitly_removed and
            not registered[definition.id] then
            local origin = register.origin(categories.ITEMS, definition.id)

            error("potion " .. definition.id .. " from " .. origin ..
                " has no effect")
        end
    end
end

return potions

-- A saved Abyssal rune is either one floor item or permanent player
-- progress. These cases exercise the production save rule directly.
local validation = require("policy.save.item_generation")
local abyss = require("constants.abyss")
local component = require("constants.component")
local harness = require("tests.harness")
local items = require("ids.items")

local test = {}

-- Supply only the ECS reads the rule needs, with production component IDs.
local function context(floor_count, collected)
    local ctx = {}
    local player = {}
    local entities = {}

    for index = 1, floor_count do
        entities[index] = {}
    end

    function ctx:player()
        return player
    end

    function ctx:query()
        return entities
    end

    function ctx:get(entity, name)
        if entity == player and name == component.PLAYER_RUNES then
            return {
                collected = collected and
                    { [items.RUNE_ABYSSAL] = true } or {},
            }
        end

        if name == component.ITEM then
            return { kind_id = items.RUNE_ABYSSAL }
        end

        if name == component.POSITION then
            return { level_id = abyss.LEVEL_ID, x = 20, y = 20 }
        end
    end

    function ctx:has()
        return false
    end

    function ctx:session_state()
        return { branch_depth = 3 }
    end

    return ctx
end

-- Duplicate floor entities, or a floor copy after pickup, would let a
-- restored game award the same rune twice.
function test.run()
    validation.abyssal_rune(context(1, false))
    validation.abyssal_rune(context(0, true))
    local duplicate_ok = pcall(function()
        validation.abyssal_rune(context(2, false))
    end)
    harness.falsy(duplicate_ok)

    local collected_ok = pcall(function()
        validation.abyssal_rune(context(1, true))
    end)
    harness.falsy(collected_ok)
end

return test

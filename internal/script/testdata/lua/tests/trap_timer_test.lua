local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.traps")
local timer = require("policy.traps.timer")

local test = {}

function test.run()
    local player = 1
    local first = 2
    local second = 3
    local traps = {
        [first] = {
            kind_id = ids.TRAP_GOLUBRIA,
            level_id = 1,
            x = 2,
            y = 2,
            charges = 2,
        },
        [second] = {
            kind_id = ids.TRAP_GOLUBRIA,
            level_id = 2,
            x = 2,
            y = 2,
            charges = 2,
        },
    }
    local destroyed = {}
    local ctx = {}

    function ctx:get(entity, schema)
        if entity == player and schema == component.POSITION then
            return {
                level_id = 1,
                x = 1,
                y = 1,
            }
        end

        if schema == component.WORLD_TRAP then
            return traps[entity]
        end
    end

    function ctx:query(schemas)
        if schemas[1] == component.WORLD_TRAP then
            return { first, second }
        end

        return {}
    end

    function ctx:set(entity, _, state)
        traps[entity] = state
    end

    function ctx:destroy(entity)
        destroyed[entity] = true
    end

    function ctx:visible()
        return true
    end

    function ctx:emit()
    end

    function ctx:random()
        error("whole-turn trap aging must not draw RNG")
    end

    timer.tick(ctx, player, 10)
    harness.equal(traps[first].charges, 1,
        "active passage loses one turn")
    harness.equal(traps[second].charges, 2,
        "inactive level passage does not age")

    timer.tick(ctx, player, 10)
    harness.truthy(destroyed[first], "expired passage closes")
    harness.falsy(destroyed[second],
        "inactive passage remains available")
end

return test

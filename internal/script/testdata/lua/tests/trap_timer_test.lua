-- Whole-turn trap aging must not draw RNG.

local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.traps")
local timer = require("policy.traps.timer")

local test = {}

-- Age traps on two levels while the player occupies one, proving whole-turn
-- charge updates are local and deterministic.
function test.run()
    local player = 1
    local first = 2
    local second = 3
    -- Two passages share the fixture but only the active level can age.
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

    -- Supply the player's active level and each trap's state; timer behavior
    -- should require no extra entity components.
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

    -- Return both traps even though only one is on the active level, making
    -- the timer's level filter part of the test.
    function ctx:query(schemas)
        if schemas[1] == component.WORLD_TRAP then
            return { first, second }
        end

        return {}
    end

    -- Persist updates in the fixture so charge changes can be inspected
    -- after the production timer returns.
    function ctx:set(entity, _, state)
        traps[entity] = state
    end

    -- Track exhausted-trap removal separately from charge changes, which
    -- catches a timer that leaves inert trap entities behind.
    function ctx:destroy(entity)
        destroyed[entity] = true
    end

    -- Keep sight permissive so this case isolates aging rather than the
    -- separate presentation rule for seen traps.
    function ctx:visible()
        return true
    end

    -- Ignore presentation messages; the timer assertions inspect trap state
    -- and must not depend on message wording.
    function ctx:emit()
    end

    -- Whole-turn aging is arithmetic only. Fail immediately if it consumes a
    -- random draw and perturbs later seeded gameplay.
    function ctx:random()
        error("whole-turn trap aging must not draw RNG")
    end

    timer.tick(ctx, player, 10)
    -- Whole-turn aging decrements charges without drawing trap RNG; the
    -- expired passage is removed while the inactive one persists.
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

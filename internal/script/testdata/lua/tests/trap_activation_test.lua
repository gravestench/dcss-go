-- Monster entry outside player sight does not activate trap.

local activation = require("policy.traps.activation")
local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.traps")

local test = {}

-- Drive a monster across a pressure plate under changing visibility, so the
-- activation signal is counted only when a crossing should trigger it.
function test.run()
    local player = 1
    local monster = 2
    local trap = 3
    -- Count emitted activations while a monster enters, waits, and then
    -- approaches from outside player sight.
    local signals = 0
    local line_of_sight = true
    local ctx = {}
    local player_position = {
        level_id = 1,
        x = 4,
        y = 5,
    }
    local site = {
        kind_id = ids.TRAP_PLATE,
        level_id = 1,
        x = 5,
        y = 5,
        charges = 0,
    }

    -- Give activation the fixture player used to evaluate sight and level.
    function ctx:player()
        return player
    end

    -- Expose just the plate for trap queries, isolating activation from any
    -- unrelated entities a full world would also contain.
    function ctx:query(schemas)
        if schemas[1] == component.WORLD_TRAP then
            return { trap }
        end

        return {}
    end

    -- Return only the components activation reads; unknown combinations stay
    -- absent so the test detects accidental new state dependencies.
    function ctx:get(entity, schema)
        if entity == player and schema == component.POSITION then
            return player_position
        end

        if entity == trap and schema == component.WORLD_TRAP then
            return site
        end
    end

    -- Toggle line of sight independently of position to test the visibility
    -- gate on emitted pressure-plate events.
    function ctx:visible()
        return line_of_sight
    end

    -- Inspect the production event payload and count emissions rather than
    -- inferring activation from the trap's local state alone.
    function ctx:signal(name, value)
        harness.equal(name, "trap.pressure_plate",
            "pressure plate dispatches a position event")
        harness.equal(value.actor, monster,
            "monster is the triggering actor")
        signals = signals + 1
    end

    local from = {
        level_id = 1,
        x = 4,
        y = 5,
    }
    local to = {
        level_id = 1,
        x = 5,
        y = 5,
    }

    activation.enter(ctx, monster, from, to)
    -- Entering the pressure plate triggers once; remaining on it does not.
    harness.equal(signals, 1, "monster entry activates trap")

    activation.enter(ctx, monster, to, to)
    harness.equal(signals, 1, "waiting on trap does not reactivate it")

    line_of_sight = false
    activation.enter(ctx, monster, from, to)
    harness.equal(signals, 1,
        "monster entry outside player sight does not activate trap")
end

return test

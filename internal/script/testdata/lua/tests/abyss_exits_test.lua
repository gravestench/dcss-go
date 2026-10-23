-- Credited XP uses the production source clock and ordinary terrain IDs.
-- This fixture supplies only the context reads and staged writes it needs.
local abyss = require("constants.abyss")
local component = require("constants.component")
local exits = require("policy.world.abyss.exits")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- Start one step from an earned gate so a large monster reward reaches
-- the threshold at any player level and shows the first exit choice.
local function context()
    local ctx = {}
    local player = {}
    local feature = terrain.DNGN_FLOOR
    local state = {
        branch_depth = 2,
        exit_xp = 1,
        exit_spawned = false,
    }
    local messages = {}

    function ctx:get(entity, name)
        harness.equal(entity, player)

        if name == component.POSITION then
            return {
                level_id = abyss.LEVEL_ID,
                x = 30,
                y = 20,
            }
        end

        if name == component.PROGRESSION then
            return { level = 10 }
        end
    end

    function ctx:session_state(name)
        harness.equal(name, abyss.SESSION_STATE)

        return state
    end

    function ctx:replace_session_state(name, next_state)
        harness.equal(name, abyss.SESSION_STATE)
        state = next_state
    end

    function ctx:cell(level_id, x, y)
        harness.equal(level_id, abyss.LEVEL_ID)
        harness.equal(x, 30)
        harness.equal(y, 20)

        return feature
    end

    function ctx:set_cell(level_id, x, y, next_feature)
        harness.equal(level_id, abyss.LEVEL_ID)
        harness.equal(x, 30)
        harness.equal(y, 20)
        feature = next_feature
    end

    function ctx:random(_, bound)
        harness.truthy(bound > 0)

        return 0
    end

    function ctx:emit(_, message)
        messages[#messages + 1] = message
    end

    return ctx, player, function()
        return state, feature, messages
    end, function(next_feature)
        feature = next_feature
    end
end

-- The first earned gate leads out; after one gate has spawned, the
-- source can choose a downward stair before the final branch depth.
function test.run()
    local ctx, player, result, set_feature = context()

    exits.award(ctx, player, 100000)

    local state, feature, messages = result()

    harness.equal(feature, terrain.DNGN_EXIT_ABYSS)
    harness.equal(state.exit_xp, abyss.EXIT_XP_COST)
    harness.truthy(state.exit_spawned)
    harness.equal(#messages, 1)

    state.exit_xp = 1
    set_feature(terrain.DNGN_FLOOR)
    exits.award(ctx, player, 100000)

    state, feature, messages = result()

    harness.equal(feature, terrain.DNGN_ABYSSAL_STAIR)
    harness.equal(state.exit_xp, abyss.EXIT_XP_COST)
    harness.equal(#messages, 2)

    -- An authored critical feature is left alone; the earned gate waits.
    state.exit_xp = 1
    set_feature(terrain.DNGN_ABYSSAL_STAIR)
    exits.award(ctx, player, 100000)

    state, feature, messages = result()

    harness.equal(state.exit_xp, 0)
    harness.equal(feature, terrain.DNGN_ABYSSAL_STAIR)
    harness.equal(#messages, 2)
end

return test

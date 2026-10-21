-- One saved choice puts the Serpent of Hell in exactly one branch ending.
-- The placement hook reads the player's unique history, so a revisit or
-- save/restore cannot redraw a different home for the same unique monster.
local branches = require("ids.branches")
local component = require("constants.component")
local history = require("policy.population.unique_history")
local serpent = require("policy.generation.hell.serpent")
local choices = require("constants.unique_choices")
local harness = require("tests.harness")

local test = {}

-- Supply only the ECS and RNG operations used by the production policy.
local function context()
    local state = {
        status = {},
        monsters = {},
        pan_states = {},
        boris_killed = false,
        choices = {},
    }
    local draws = 0
    local ctx = {}

    function ctx:player()
        return 1
    end

    function ctx:get(entity, id)
        assert(entity == 1 and id == component.PLAYER_UNIQUE_HISTORY)
        return state
    end

    function ctx:set(entity, id, value)
        assert(entity == 1 and id == component.PLAYER_UNIQUE_HISTORY)
        state = value
    end

    function ctx:random(_, bound)
        assert(bound == 4)
        draws = draws + 1
        return 2
    end

    return ctx, function()
        return state, draws
    end
end

-- The first draw persists; all later reads, including after a simulated
-- restore from the same saved component, must leave the RNG untouched.
local function choice_persists()
    local ctx, snapshot = context()
    local selected = serpent.branch(ctx)
    local state, draws = snapshot()

    harness.equal(selected, branches.BRANCH_DIS)
    harness.equal(state.choices[choices.HELL_SERPENT_BRANCH], selected)
    harness.equal(draws, 1)
    harness.equal(serpent.branch(ctx), selected)

    _, draws = snapshot()
    harness.equal(draws, 1)
    history.validate(state)
end

-- A modded or corrupted save must not send the unique into an unknown
-- branch, because that would silently remove it from all four endings.
local function rejects_unknown_saved_branch()
    local ctx, snapshot = context()
    serpent.branch(ctx)
    local state = snapshot()

    state.choices[choices.HELL_SERPENT_BRANCH] = "BRANCH_DUNGEON"
    assert(not pcall(history.validate, state))
end

-- Run both the persistence and corrupt-save contracts in the production VM.
function test.run()
    choice_persists()
    rejects_unknown_saved_branch()
end

return test

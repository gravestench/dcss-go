-- Orb-run timing and defender selection use production Lua policy. This
-- fixture supplies only deterministic random draws; it does not copy the
-- monster catalogs, source weights, or the saved component schema.
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- Return queued source draws and reject a wrong stream or draw bound.
local function draw_context(draws)
    local index = 0
    local ctx = {}

    function ctx:random(stream, bound)
        harness.equal(stream, streams.ORB_RUN, "Orb-run stream")

        index = index + 1

        local draw = draws[index]

        harness.truthy(draw ~= nil and draw >= 0 and draw < bound,
            "Orb-run draw bound " .. bound)

        return draw
    end

    function ctx:player()
        return 1
    end

    function ctx:get()
        return nil
    end

    function ctx:draws_used()
        return index
    end

    return ctx
end

-- Five-turn boundaries are measured from the saved absolute clock. Source
-- defender categories are chosen only after the 5-in-18 spawn gate succeeds.
function test.run()
    local ok, run = pcall(require, "policy.character.orb_run")

    harness.truthy(ok and run, "Orb-run policy is registered")
    harness.equal(run.boundaries(0, 49), 0, "before first source tick")
    harness.equal(run.boundaries(49, 2), 1, "cross first source tick")
    harness.equal(run.boundaries(50, 100), 2, "cross two more ticks")

    local guardian = draw_context({ 1, 0, 0 })

    harness.equal(run.pick_defender(guardian),
        monsters.MONS_ORB_GUARDIAN, "guardian category")
    harness.equal(guardian:draws_used(), 3, "guardian draw budget")

    local lord = draw_context({ 0, 1 })

    harness.equal(run.pick_defender(lord),
        monsters.MONS_PANDEMONIUM_LORD, "rare lord category")
end

return test

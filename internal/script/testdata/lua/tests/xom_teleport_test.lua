-- Xom's two teleport journeys share the real teleport owner, but stop
-- under different source probabilities after each successful attempt.
local events = require("policy.religion.xom.events")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local streams = require("constants.rng_streams")
local teleport = require("policy.magic.player_teleport")
local tension = require("policy.combat.monster_seal_tension")

local test = {}

-- A one-in-ten good stop fires immediately; the bad journey draws its
-- count cap first and stops when its three-in-four continuation fails.
function test.run(ctx)
    local player = ctx:create()
    local original_teleport = teleport.now
    local original_tension = tension.current
    local jumps = 0
    local draws = {
        { bound = 10, value = 0 },
        { bound = 5, value = 0 },
        { bound = 4, value = 3 },
    }
    local index = 0
    local proxy = setmetatable({}, { __index = ctx })

    -- Count calls into the production teleport owner, while the two
    -- event loops retain their actual branching and RNG draw order.
    teleport.now = function()
        jumps = jumps + 1
        return true
    end

    tension.current = function()
        return 0
    end

    function proxy:random(stream, bound)
        index = index + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, draws[index].bound)

        return draws[index].value
    end

    local good = events.apply(proxy, player,
        ids.GOOD_TELEPORT, 20, {
            stream = streams.RELIGION,
        })
    local bad = events.apply(proxy, player,
        ids.BAD_TELEPORT, 20, {
            stream = streams.RELIGION,
        })

    teleport.now = original_teleport
    tension.current = original_tension

    harness.equal(good, 1)
    harness.equal(bad, 1)
    harness.equal(jumps, 2)
    harness.equal(index, #draws)
end

return test

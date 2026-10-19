-- The chaos beam uses the source's weighted flavour pool, independent of
-- melee Chaos branding. Boundary draws catch an accidentally omitted rare
-- effect without redeclaring the production weights in this test.
local flavours = require("constants.beam_flavours")
local harness = require("tests.harness")
local pool = require("policy.combat.monster_area.chaos_flavours")
local streams = require("constants.rng_streams")

local test = {}

-- Supply one deterministic saved-stream draw and verify the source pool's
-- total weight as well as the selected effect.
local function draw_at(index)
    local ctx = {}

    -- One forced draw checks both saved-stream choice and total pool size.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.MONSTER_SPELL,
            "chaos uses the saved monster-spell stream")
        harness.equal(bound, 505,
            "all twenty-six source flavours retain their weights")

        return index
    end

    return pool.choose(ctx, streams.MONSTER_SPELL)
end

-- The first five large elemental bands and the final rare enchantment must
-- remain reachable at the exact ends of the source weighted interval.
function test.run()
    harness.equal(draw_at(0), flavours.BEAM_FIRE,
        "first source band is fire")
    harness.equal(draw_at(70), flavours.BEAM_COLD,
        "the next elemental band begins after seventy draws")
    harness.equal(draw_at(504), flavours.BEAM_ENSNARE,
        "the final source band is ensnare")
end

return test

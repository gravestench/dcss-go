-- The source's common demon alias chooses tier four 60% of the time.
local harness = require("tests.harness")
local ids = require("ids.monsters")
local random_monsters = require("policy.generation.vaults.specs.random_monsters")

local test = {}

-- Boundary draws prove the source tier weighting and six-member uniform
-- pool without copying an alternate list of demon IDs into this fixture.
local function source_tier_boundaries()
    local ctx = {}
    local draws = { 5, 0, 6, 5 }
    local next_draw = 0

    function ctx:random(stream, bound)
        harness.equal(stream, "vault_monster", "demon draw stream")
        next_draw = next_draw + 1

        if next_draw == 1 or next_draw == 3 then
            harness.equal(bound, 10, "tier choice has ten outcomes")
        else
            harness.equal(bound, 6, "each tier has six demons")
        end

        return draws[next_draw]
    end

    harness.equal(random_monsters.pick(ctx, "common demon", 10),
        ids.MONS_ICE_DEVIL, "tier-four boundary")
    harness.equal(random_monsters.pick(ctx, "any common demon", 10),
        ids.MONS_SIXFIRHY, "tier-three boundary")
end

-- Both source aliases must resolve through the same tier draw and not
-- fall into the ordinary branch population picker.
function test.run()
    source_tier_boundaries()
end

return test

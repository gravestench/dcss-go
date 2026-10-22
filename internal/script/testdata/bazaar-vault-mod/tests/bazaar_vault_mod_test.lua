-- A sparse layer adds one complete Bazaar without replacing the base pool.
-- Candidate order is by stable ID, never by filesystem discovery order.
local bazaar = require("policy.generation.bazaar.level")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local species = require("ids.species")

local test = {}

-- The effective selector sees the modded map and preserves its authored
-- weight. Sorting the returned IDs prevents file order from shifting draws.
function test.run()
    local candidates = bazaar.candidates({
        species_id = species.SP_HUMAN,
    })
    local found = false
    local previous = ""
    local total = 0

    for _, candidate in ipairs(candidates) do
        harness.truthy(previous < candidate.id,
            "Bazaar pool is not in stable ID order")

        previous = candidate.id
        total = total + candidate.weight

        if candidate.id == "modded_bazaar_stall" then
            harness.equal(candidate.weight, 5000,
                "modded Bazaar source weight")

            found = true
        end
    end

    harness.equal(#candidates, 43, "modded Bazaar joins source pool")
    harness.truthy(found, "modded Bazaar map was not discovered")

    -- The first layout draw selects the last weighted span. Later draws
    -- stay bounded so the real placement path can finish this tiny map.
    local context = {
        first_draw = true,
    }

    function context:random_u64()
        if self.first_draw then
            self.first_draw = false

            return 0, total - 1
        end

        return 1, 1
    end

    local generated = bazaar.generate(context, {
        species_id = species.SP_HUMAN,
        player_name = "Modder",
    })
    local level = generated.level
    local shop = false

    for _, record in ipairs(level.vault_records) do
        shop = shop or record.kind == effects.FEATURE and
            record.identity == "general shop"
    end

    harness.equal(level.vault_id, "modded_bazaar_stall",
        "modded Bazaar selected through production generator")
    harness.truthy(shop, "modded Bazaar lost its authored shop")
end

return test

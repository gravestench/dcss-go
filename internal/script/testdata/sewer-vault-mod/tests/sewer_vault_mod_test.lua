-- A sparse layer adds one Sewer map without replacing the source corpus.
-- Candidate order is the stable ID order, even when paths load differently.
local sewer = require("policy.generation.sewer.level")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- Select the final weight span to prove an added file reaches the real
-- generator. Its exit must survive the same terrain projection as built-ins.
function test.run()
    local candidates = sewer.candidates({})
    local previous = ""
    local total = 0
    local found = false

    for _, candidate in ipairs(candidates) do
        harness.truthy(previous < candidate.id,
            "Sewer pool is not in stable ID order")

        previous = candidate.id
        total = total + candidate.weight

        if candidate.id == "zz_modded_sewer_channel" then
            harness.equal(candidate.weight, 5000,
                "modded Sewer source weight")

            found = true
        end
    end

    harness.equal(#candidates, 20, "modded Sewer joins source pool")
    harness.truthy(found, "modded Sewer map was not discovered")

    local context = { first_draw = true }

    function context:random_u64()
        if self.first_draw then
            self.first_draw = false

            return 0, total - 1
        end

        return 1, 1
    end

    local generated = sewer.generate(context, {})
    local level = generated.level

    harness.equal(level.vault_id, "zz_modded_sewer_channel",
        "modded Sewer selected through production generator")

    local exit_found = false

    for _, row in ipairs(level.cells) do
        for _, feature in ipairs(row) do
            exit_found = exit_found or feature == terrain.DNGN_EXIT_SEWER
        end
    end

    harness.truthy(exit_found, "modded Sewer lost its return exit")
end

return test

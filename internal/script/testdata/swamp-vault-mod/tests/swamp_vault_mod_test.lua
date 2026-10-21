-- A sparse layer extends the same effective Swamp catalog as bundled maps.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local regular = require("policy.generation.vaults.regular")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The weighted selector and named hook resolver must both see mod files.
function test.run()
    local candidates = regular.candidates({
        branch_id = branches.BRANCH_SWAMP,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
        branch_vault_family = "swamp",
    })
    local found = false

    for _, candidate in ipairs(candidates) do
        if candidate.definition.id == "modded_swamp_lily" then
            found = true
            harness.equal(candidate.weight, 7,
                "modded Swamp weight survives catalog selection")
        end
    end

    harness.truthy(found, "modded Swamp map joins the regular pool")

    local expanded = hooks.expand(vaults.get("modded_swamp_lily"), {})
    local emitted = false

    for _, operation in ipairs(expanded) do
        if operation.kind == directives.SUBST and
            operation.argument == "s = w" then
            emitted = true
        end
    end

    harness.truthy(emitted, "modded hook emits its own terrain policy")
end

return test

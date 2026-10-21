-- The effective layered vault catalog can replace and extend whole-floor
-- Depths maps without changing the engine's list of candidates.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local families = require("constants.vault_families")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local encompass = require("policy.generation.vaults.encompass")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Both the replaced ID and the new ID retain source-style weights in a
-- stable candidate order; the new map's hook resolves from the mod layer.
function test.run()
    local candidates = encompass.candidates({
        branch_id = branches.BRANCH_DEPTHS,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 23,
        family = families.DEPTHS_ENCOMPASS,
    })
    local weights = {}

    for _, candidate in ipairs(candidates) do
        weights[candidate.definition.id] = candidate.weight
    end

    harness.equal(#candidates, 6, "new encompass joins the middle pool")
    harness.equal(weights.box_level_dp, 3, "same-path override wins")
    harness.equal(weights.modded_depths_hall, 7, "new map joins by discovery")

    local operations = hooks.expand(vaults.get("modded_depths_hall"), {})
    local emitted = false

    for _, operation in ipairs(operations) do
        if operation.kind == directives.SUBST and
            operation.argument == ". = ." then
            emitted = true
        end
    end

    harness.truthy(emitted, "modded named hook executes")
end

return test

-- A sparse overlay can replace one source map and add another, including
-- its Lua hook, without changing the embedded catalog or engine code.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local families = require("constants.vault_families")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local layouts = require("policy.generation.layouts.catalog")
local regular = require("policy.generation.vaults.regular")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The override changes only the dummy's effective weight on Zot:5.
-- The new shrine joins Zot:2 through ordinary family discovery.
function test.run()
    local middle = regular.candidates({
        branch_id = branches.BRANCH_ZOT,
        depth = 2,
        branch_bottom = 5,
        absolute_depth = 28,
        branch_vault_family = families.ZOT,
    })
    local bottom = regular.candidates({
        branch_id = branches.BRANCH_ZOT,
        depth = 5,
        branch_bottom = 5,
        absolute_depth = 31,
        branch_vault_family = families.ZOT,
    })
    local middle_weights = {}
    local bottom_weights = {}

    for _, candidate in ipairs(middle) do
        middle_weights[candidate.definition.id] = candidate.weight
    end

    for _, candidate in ipairs(bottom) do
        bottom_weights[candidate.definition.id] = candidate.weight
    end

    harness.equal(middle_weights.modded_zot_shrine, 7,
        "new Zot map joins by path discovery")
    harness.equal(bottom_weights.dummy_balancer_zot, 1,
        "same-path source dummy override wins")

    local operations = hooks.expand(vaults.get("modded_zot_shrine"), {})
    local emitted = false

    for _, operation in ipairs(operations) do
        if operation.kind == directives.SUBST and
            operation.argument == ". = ." then
            emitted = true
        end
    end

    harness.truthy(emitted, "sparse mod hook executes")

    local random = {
        roll = function(_, bound)
            return bound - 1
        end,
    }
    local final = layouts.choose(random, branches.BRANCH_ZOT, 5, 5)

    harness.equal(final.id, "hall_of_Zot",
        "an added PLACE layout cannot displace the required Hall")
end

return test

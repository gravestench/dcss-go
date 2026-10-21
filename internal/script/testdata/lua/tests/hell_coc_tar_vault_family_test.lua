-- Every ordinary Cocytus and Tartarus source map remains an independent
-- definition and survives the production DES hook and placement pipeline.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local regular = require("policy.generation.vaults.regular")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Give each map a fresh deterministic grid while using the real pipeline.
local function random_context()
    local state = 71
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state
        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Place every source definition and verify the branch's normal pool can
-- discover it without registering any family specific Go or Lua list.
local function check_family(family, branch_id, expected)
    local count = 0
    local player = {
        branch_id = branch_id,
        depth = 2,
        branch_bottom = 7,
        absolute_depth = 25,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == family then
            count = count + 1
            if id == "nicolae_sub_coc_subbean" then
                harness.equal(#definition.depths, 0,
                    "icebean subvault keeps its source-only helper role")
            else
                harness.truthy(#definition.depths > 0,
                    id .. " lost its source depth")
            end

            local placed = placement.place(nil,
                grid.new(random_context()), definition, player)

            harness.equal(placed.id, id,
                family .. " map keeps its source identity")
        end
    end

    harness.equal(count, expected, family .. " ordinary source map count")

    local context = {
        branch_id = branch_id,
        depth = 2,
        branch_bottom = 7,
        absolute_depth = 25,
        branch_vault_family = family,
    }
    local candidates = regular.candidates(context)

    harness.truthy(#candidates > 0,
        family .. " maps must enter the ordinary pool")

    for _, candidate in ipairs(candidates) do
        harness.equal(candidate.definition.family, family,
            "another branch entered the " .. family .. " pool")
    end
end

-- The pinned ordinary sections contain 26 Coc and 39 Tar definitions.
function test.run()
    vaults.load()
    check_family("coc", branches.BRANCH_COCYTUS, 26)
    check_family("tar", branches.BRANCH_TARTARUS, 39)
end

return test

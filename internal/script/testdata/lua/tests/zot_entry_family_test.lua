-- Zot's Depths-side entry is chosen from complete source-authored maps.
-- This test uses production placement, so a hook or KFEAT that no longer
-- works cannot hide behind a catalog count.
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local entry = require("policy.generation.vaults.branch_entry")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Independent streams keep one map's draw count from concealing another
-- map's placement fault when the catalog changes.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

function test.run()
    local floor = {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 25,
    }
    local choices = entry.candidates(branches.BRANCH_ZOT, floor)

    harness.equal(#choices, 14, "fourteen large Zot entries")

    for _, choice in ipairs(choices) do
        local definition = vaults.get(choice.definition.id)
        local builder = grid.new(random_context(#definition.id + 47))
        local placed = placement.place(nil, builder, definition, floor)
        local gates = 0

        for _, record in ipairs(placed.records) do
            if record.kind == effects.FEATURE and
                record.identity == features.ENTER_ZOT then
                gates = gates + 1
            end
        end

        harness.equal(gates, 1,
            definition.id .. " resolves one source Zot gate")
    end
end

return test

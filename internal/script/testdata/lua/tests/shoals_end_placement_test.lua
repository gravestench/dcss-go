-- Exercise every Shoals finale through the production DES and end-vault
-- paths. The mapless controllers must assemble tagged child islands before
-- a floor can claim that it contains the barnacled rune.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local effects = require("constants.vault_effects")
local end_vault = require("policy.generation.vaults.end")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local items = require("ids.items")
local used = require("policy.generation.vaults.used")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Give each authored map a connected floor and a reproducible layout stream.
local function floor_for(seed)
    local state = seed
    local ctx = {}

    function ctx:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    local builder = grid.new(ctx)

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    return ctx, builder
end

-- End policy and placement need the same captured facts as a live Shoals:4.
local function context_for(id)
    return {
        branch_id = branches.BRANCH_SHOALS,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        end_vault_family = "shoals_end",
        end_choice = { id = id },
        protected = {},
        required = {},
        used = used.new({}),
        player = {
            branch_id = branches.BRANCH_SHOALS,
            depth = 4,
            branch_bottom = 4,
            absolute_depth = 18,
        },
    }
end

-- Controller records may live in children, whereas encompass records may
-- live in a nested SUBVAULT. Count the resolved intent after composition.
local function count_runes(placed)
    local count = 0

    for _, map in ipairs(placed) do
        for _, record in ipairs(map.records or {}) do
            if record.kind == effects.ITEM and record.arguments and
                record.arguments.kind_id == items.RUNE_SHOALS and
                not record.arguments.mimic then
                count = count + 1
            end
        end
    end

    return count
end

-- A selected finale must remain the primary ID and provide one real rune.
function test.run()
    vaults.load()

    local branch = register.get(categories.BRANCHES, branches.BRANCH_SHOALS)
    local candidates = end_vault.candidates(context_for(nil))

    harness.truthy(branch.end_vault_required, "Shoals end is mandatory")
    harness.equal(#candidates, 6, "all six source finales are selectable")

    for index, candidate in ipairs(candidates) do
        local id = candidate.definition.id
        local ctx, builder = floor_for(index * 109 + 37)
        local context = context_for(id)
        local placed = {}
        local selected = end_vault.place(ctx, builder, context,
            placed, extra.place)

        harness.equal(selected, id, "finale keeps its selected ID")
        harness.equal(count_runes(placed), 1,
            id .. " supplies exactly one real rune")
    end
end

return test

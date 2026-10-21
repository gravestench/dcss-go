-- Source Snake maps remain independently discoverable after the original
-- file-level default depth has been made explicit in each DES definition.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local families = require("constants.vault_families")
local features = require("constants.vault_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local branch_entry = require("policy.generation.vaults.branch_entry")
local minivault = require("policy.generation.vaults.minivault")
local placement = require("policy.generation.vaults.placement")
local regular = require("policy.generation.vaults.regular")
local vaults = require("policy.generation.vaults.catalog")
local tags = require("constants.vault_tags")

local test = {}

-- A fresh deterministic layout stream gives each source definition an
-- independent placement attempt through the real DES operation engine.
local function random_context()
    local state = 41
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Run source substitutions and keyed effects, not a test-only parser.
local function place(definition, branch_id, depth, absolute_depth)
    local builder = grid.new(random_context())
    local player = {
        branch_id = branch_id,
        depth = depth,
        branch_bottom = branch_id == branches.BRANCH_LAIR and 5 or 4,
        absolute_depth = absolute_depth,
    }

    return placement.place(nil, builder, definition, player)
end

-- Every source entrance must author exactly one Snake stair; ordinary
-- source maps must stay in Snake's depth-qualified family.
function test.run()
    vaults.load()

    local entries = 0
    local ordinary = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == families.SNAKE_ENTRY then
            entries = entries + 1

            harness.truthy(definition.tags[tags.SNAKE_ENTRY],
                id .. " lost its source entry tag")

            local placed = place(definition, branches.BRANCH_LAIR, 3, 11)
            local entrances = 0

            for _, record in ipairs(placed.records) do
                if record.kind == effects.FEATURE and
                    record.directive == directives.KFEAT and
                    record.identity == features.ENTER_SNAKE then
                    entrances = entrances + 1
                end
            end

            harness.equal(entrances, 1,
                id .. " must author one Snake stair")
        elseif definition.family == families.SNAKE then
            ordinary = ordinary + 1

            harness.truthy(#definition.depths > 0,
                id .. " lost its inherited Snake depth")

            local placed = place(definition, branches.BRANCH_SNAKE, 2, 16)

            harness.equal(placed.id, id,
                "ordinary map keeps its authored identity")
        end
    end

    harness.equal(entries, 8, "source Snake entrance count")
    harness.equal(ordinary, 68, "source ordinary Snake count")

    local entrance_candidates = branch_entry.candidates(
        branches.BRANCH_SNAKE)

    harness.equal(#entrance_candidates, entries,
        "scheduled Snake selector sees every effective entry")

    local context = {
        branch_id = branches.BRANCH_SNAKE,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
        branch_vault_family = families.SNAKE,
    }
    local ordinary_candidates = 0

    for _, candidate in ipairs(regular.candidates(context)) do
        harness.equal(candidate.definition.family, families.SNAKE,
            "non-Snake map entered the regular pool")
        ordinary_candidates = ordinary_candidates + 1
    end

    for _, candidate in ipairs(minivault.candidates(context)) do
        if candidate.definition.family == families.SNAKE then
            ordinary_candidates = ordinary_candidates + 1
        end
    end

    harness.truthy(ordinary_candidates > 0,
        "Snake floors have no ordinary source maps")
end

return test

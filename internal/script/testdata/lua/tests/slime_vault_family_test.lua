-- The effective DES catalog, not a hand-maintained Go roster, owns every
-- non-finale source Slime map. Each entry must place one real stair cell.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local families = require("constants.vault_families")
local features = require("constants.vault_features")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local branch_entry = require("policy.generation.vaults.branch_entry")
local placement = require("policy.generation.vaults.placement")
local regular = require("policy.generation.vaults.regular")
local minivault = require("policy.generation.vaults.minivault")
local vaults = require("policy.generation.vaults.catalog")
local tags = require("constants.vault_tags")

local test = {}

-- A fresh deterministic source drives each source operation independently.
local function context()
    local state = 29
    local ctx = {}

    function ctx:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return ctx
end

-- Run the production DES operation engine so malformed keyed expressions,
-- source substitutions, and one-entrance invariants fail near the map.
local function place(definition, branch_id, depth, absolute_depth)
    local builder = grid.new(context())
    local player = {
        branch_id = branch_id or branches.BRANCH_LAIR,
        depth = depth or 5,
        branch_bottom = 5,
        absolute_depth = absolute_depth or 13,
    }

    return placement.place(nil, builder, definition, player)
end

-- Exercise the selector independently of map geometry. The production
-- fitter is covered by the source-map and live-travel tests; here a failed
-- fit must consume only its candidate, then leave the source stair fallback.
local function check_entry_retries()
    local definitions = branch_entry.candidates(branches.BRANCH_SLIME)
    local original_candidates = branch_entry.candidates
    local original_place = extra.place
    local attempts = {}
    local builder = grid.new(context())
    local protected = {}

    -- Always draw the first remaining candidate so the order is explicit.
    function builder:roll()
        return 0
    end

    branch_entry.candidates = function()
        return {
            definitions[1],
            definitions[2],
        }
    end

    extra.place = function(_, _, definition)
        attempts[#attempts + 1] = definition.id

        if definition.id == definitions[1].definition.id then
            return nil
        end

        return {
            id = definition.id,
            records = {
                {
                    kind = effects.FEATURE,
                    directive = directives.KFEAT,
                    identity = features.ENTER_SLIME,
                    x = 7,
                    y = 8,
                },
            },
        }
    end

    local ok, message = pcall(function()
        local placed, point = branch_entry.place(nil, builder, protected,
            {}, {}, branches.BRANCH_SLIME)

        harness.equal(#attempts, 2, "failed entry retries another map")
        harness.equal(placed.id, definitions[2].definition.id,
            "retry keeps the successful source map")
        harness.equal(point.x, 7, "source stair x survives retry")
        harness.equal(point.y, 8, "source stair y survives retry")
        harness.equal(builder:cell(7, 8), ">",
            "successful entry writes the linked stair")

        attempts = {}
        extra.place = function(_, _, definition)
            attempts[#attempts + 1] = definition.id

            return nil
        end

        local absent, fallback = branch_entry.place(nil, builder, {},
            {}, {}, branches.BRANCH_SLIME)

        harness.equal(#attempts, 2, "every failed entry is tried once")
        harness.equal(absent, nil, "exhausted entry leaves no map")
        harness.equal(fallback, nil,
            "exhausted entry requests the single-stair fallback")
    end)

    branch_entry.candidates = original_candidates
    extra.place = original_place

    if not ok then
        error(message)
    end
end

-- Every source file is auto-discovered, and only entrance files can
-- contribute an authored Lair-to-Slime stair.
function test.run()
    vaults.load()

    local entries = 0
    local ordinary = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == families.SLIME_ENTRY then
            entries = entries + 1

            harness.truthy(definition.tags[tags.SLIME_ENTRY],
                id .. " lost its source entry tag")

            local placed = place(definition)
            local entrances = 0

            for _, record in ipairs(placed.records) do
                if record.kind == effects.FEATURE and
                    record.directive == directives.KFEAT and
                    record.identity == features.ENTER_SLIME then
                    entrances = entrances + 1
                end
            end

            harness.equal(entrances, 1,
                id .. " must author exactly one Slime stair")
        elseif definition.family == families.SLIME then
            ordinary = ordinary + 1

            harness.truthy(#definition.depths > 0,
                id .. " needs source Slime DEPTH")

            local okay, placed = pcall(place, definition,
                branches.BRANCH_SLIME, 2, 18)

            harness.truthy(okay,
                id .. " source operations failed: " .. tostring(placed))
            harness.equal(placed.id, id,
                "ordinary map keeps its authored identity")
        end
    end

    harness.equal(entries, 10, "source Slime entrance count")
    harness.equal(ordinary, 18, "source ordinary Slime count")

    local candidates = branch_entry.candidates(branches.BRANCH_SLIME)

    harness.equal(#candidates, entries,
        "scheduled Slime selector sees each effective entry")

    for _, candidate in ipairs(candidates) do
        harness.equal(candidate.definition.family, families.SLIME_ENTRY,
            "ordinary map escaped into the branch entry pool")
    end

    local context = {
        branch_id = branches.BRANCH_SLIME,
        depth = 2,
        branch_bottom = 5,
        absolute_depth = 18,
        branch_vault_family = families.SLIME,
    }
    local regular_maps = regular.candidates(context)
    local small_maps = 0

    for _, candidate in ipairs(minivault.candidates(context)) do
        if candidate.definition.family == families.SLIME then
            small_maps = small_maps + 1
        end
    end

    harness.equal(#regular_maps, 8,
        "explicitly oriented Slime maps enter regular selection")
    harness.equal(small_maps, 10,
        "source mini Slime maps enter ordinary selection")

    context.depth = 5
    context.absolute_depth = 21

    harness.equal(#regular.candidates(context), 0,
        "ordinary Slime maps cannot replace the finale")

    check_entry_retries()
end

return test

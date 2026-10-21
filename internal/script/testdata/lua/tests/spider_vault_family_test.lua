-- Spider maps come from two source files, but each definition is an
-- independently replaceable DES file in the effective catalog.
local categories = require("constants.catalog")
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local branch_entry = require("policy.generation.vaults.branch_entry")
local regular = require("policy.generation.vaults.regular")
local minivault = require("policy.generation.vaults.minivault")
local tags = require("constants.vault_tags")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Every map gets an independent deterministic layout stream, so a failed
-- source expression identifies its own DES file rather than a prior draw.
local function random_context()
    local state = 43
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Use the production DES operation and nested-helper path, including
-- keyed effects, instead of a test-only interpretation of the map.
local function place(definition, entry)
    local builder = grid.new(random_context())
    local player = {
        branch_id = entry and branches.BRANCH_LAIR or
            branches.BRANCH_SPIDER,
        depth = entry and 3 or 2,
        branch_bottom = entry and 5 or 4,
        absolute_depth = entry and 11 or 16,
    }

    return placement.place(nil, builder, definition, player)
end

-- Exact family counts catch a missing map even if ordinary selection
-- still has enough candidates to generate a floor.
function test.run()
    vaults.load()

    local entries = 0
    local ordinary = 0
    local jumping = 0
    local finales = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == "spider_entry" then
            entries = entries + 1

            harness.truthy(definition.tags[tags.SPIDER_ENTRY],
                id .. " lost its source entrance tag")

            local placed = place(definition, true)
            local gates = 0

            for _, record in ipairs(placed.records) do
                if record.kind == effects.FEATURE and
                    record.directive == directives.KFEAT and
                    record.identity == features.ENTER_SPIDER then
                    gates = gates + 1
                end
            end

            harness.equal(gates, 1,
                id .. " must author one Spider gate")
        elseif definition.family == "spider" then
            local ok, placed = pcall(place, definition, false)

            harness.truthy(ok,
                id .. " source operations failed: " .. tostring(placed))
            harness.equal(placed.id, id,
                "authored Spider map keeps its source identity")

            if id:match("^nicolae_spider_jumping_") then
                jumping = jumping + 1

                if id:match("_sub_") then
                    harness.truthy(definition.tags[tags.SPIDER_JUMPING_CHILD],
                        id .. " must join the jumping helper pool")
                    harness.truthy(definition.tags.unrand,
                        id .. " must not enter the ordinary draw")
                end
            else
                ordinary = ordinary + 1
            end
        elseif definition.family == "spider_end" then
            finales = finales + 1
        end
    end

    harness.equal(entries, 11, "source Spider entrance maps")
    harness.equal(ordinary, 66, "source ordinary Spider maps")
    harness.equal(jumping, 17, "source jumping Spider maps")
    harness.equal(finales, 9, "mandatory Spider finale maps")

    local candidate_entries = branch_entry.candidates(
        branches.BRANCH_SPIDER)

    harness.equal(#candidate_entries, entries,
        "scheduled Spider entry sees every source map")

    for _, candidate in ipairs(candidate_entries) do
        harness.equal(candidate.definition.family, "spider_entry",
            "ordinary map escaped into entry selection")
    end

    local ordinary_candidates = regular.candidates({
        branch_id = branches.BRANCH_SPIDER,
        branch_vault_family = "spider",
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
    })

    for _, candidate in ipairs(ordinary_candidates) do
        harness.falsy(candidate.definition.tags[tags.SPIDER_JUMPING_CHILD],
            "jumping helper escaped into ordinary selection")
    end

    local zot_candidates = minivault.candidates({
        branch_id = branches.BRANCH_ZOT,
        depth = 2,
        branch_bottom = 5,
        absolute_depth = 27,
    })
    local trapstep_found = false

    for _, candidate in ipairs(zot_candidates) do
        if candidate.definition.id == "hangedman_spider_trapstep" then
            trapstep_found = true
        end
    end

    harness.truthy(trapstep_found,
        "source Spider trapstep must also be eligible on Zot:2")
end

return test

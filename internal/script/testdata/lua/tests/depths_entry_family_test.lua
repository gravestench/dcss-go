-- All eight source Depths gates must be discoverable through the same
-- effective catalog and branch-entry path used by live D:15 generation.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local entry = require("policy.generation.vaults.branch_entry")
local families = require("constants.vault_families")
local features = require("constants.vault_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local tags = require("constants.vault_tags")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Supply an independent reproducible stream to each source map so a
-- placement failure names the map and directive that caused it.
local function random_context()
    local state = 97
    local context = {}

    -- The grid builder requests two 32-bit halves per random draw.
    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- A keyed source gate, not a bare MAP glyph, owns the scheduled stair.
local function source_gate(map)
    local found = 0

    for _, record in ipairs(map.records) do
        if record.kind == effects.FEATURE and
            record.directive == directives.KFEAT and
            record.identity == features.ENTER_DEPTHS then
            found = found + 1
        end
    end

    return found
end

-- Check the complete family and its effective weighted candidate pool.
function test.run()
    vaults.load()

    local count = 0
    local total_weight = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == families.DEPTHS_ENTRY then
            harness.truthy(definition.tags[tags.DEPTHS_ENTRY],
                id .. " retains its source selector tag")

            local builder = grid.new(random_context())
            local player = {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 15,
                branch_bottom = 15,
                absolute_depth = 15,
            }
            local okay, map = pcall(placement.place, nil, builder,
                definition, player)

            harness.truthy(okay, id .. " placement: " .. tostring(map))
            harness.equal(source_gate(map), 1,
                id .. " owns one keyed Depths gate")
            count = count + 1
            total_weight = total_weight + definition.weight
        end
    end

    harness.equal(count, 8, "all source Depths entry maps")
    harness.equal(#entry.candidates(branches.BRANCH_DEPTHS), 8,
        "all source Depths entry candidates")
    harness.equal(total_weight, 152,
        "seven default weights and one source override")
end

return test

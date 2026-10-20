-- Source Temple maps must become real shared-grid placements before the
-- scheduled entrance is opened. Exercise every eligible count and rare map.
local branches = require("ids.branches")
local catalog = require("policy.generation.temple.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local settings = require("constants.temple_settings")
local directives = require("constants.vault_directives")
local features = require("constants.vault_features")

local test = {}

-- Fresh builders keep placements independent while source choices use a
-- deterministic layout stream. No alternate test-only DES parser is used.
local function place(definition, altar_count, branch_id, depth)
    local context = {}

    function context:random_u64()
        return 0, 0
    end

    local builder = grid.new(context)
    local player = {
        branch_id = branch_id or branches.BRANCH_TEMPLE,
        depth = depth or 1,
        branch_bottom = branch_id == branches.BRANCH_DUNGEON and 15 or 1,
        absolute_depth = depth or 1,
        settings = {
            [settings.ALTAR_COUNT] = altar_count,
        },
    }

    return placement.place(nil, builder, definition, player)
end

-- Every advertised count must execute the same operations that live
-- generation will run, including source hook emissions and keyed records.
function test.run()
    for _, id in ipairs(catalog.main_ids()) do
        local definition = catalog.main(id)

        for tag in pairs(definition.tags) do
            local text = tag:match("^temple_altars_(%d+)$")

            if text then
                local count = tonumber(text)
                local okay, placed = pcall(place, definition, count)

                harness.truthy(okay,
                    id .. " count " .. count .. " failed: " ..
                    tostring(placed))
                harness.equal(placed.id, id,
                    "placement keeps the selected source map ID")

            end
        end
    end

    for _, id in ipairs(catalog.entry_ids()) do
        local definition = catalog.entry(id)
        local okay, placed = pcall(place, definition, nil,
            branches.BRANCH_DUNGEON, 5)

        harness.truthy(okay, id .. " entry failed: " .. tostring(placed))

        local entrances = 0

        for _, record in ipairs(placed.records) do
            if record.directive == directives.KFEAT and
                record.identity == features.ENTER_TEMPLE then
                entrances = entrances + 1
            end
        end

        harness.equal(entrances, 1,
            id .. " must place exactly one source Temple entrance")
    end

end

return test

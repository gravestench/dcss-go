-- Pandemonium divisions are two authored encompass layouts assembled
-- from twenty weighted, tag-only helper maps in the source builder file.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local layout_catalog = require("policy.generation.layouts.catalog")
local vault_catalog = require("policy.generation.vaults.catalog")
local placement = require("policy.generation.vaults.placement")

local test = {}
local EXPECTED_FAMILY_COUNT = 22

-- Source IDs rather than filenames define the family. All children must
-- load before either parent can resolve a SUBVAULT tag.
local function family_contract(ctx)
    local count = 0
    local player = {
        branch_id = branches.BRANCH_PANDEMONIUM,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 24,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if id:match("^pan_division_") then
            count = count + 1

            local helper = vault_catalog.get(id)

            harness.truthy(#helper.rows > 0,
                id .. " lost its authored cells")
            harness.equal(#helper.depths, 0,
                id .. " entered a random branch pool")

            local placed = placement.place(nil, grid.new(ctx),
                helper, player)

            harness.equal(placed.id, id,
                id .. " resolves all authored directives")
        end
    end

    count = count + 2
    harness.equal(count, EXPECTED_FAMILY_COUNT,
        "source Pan divisions family count")
end

-- Both layouts must assemble their helpers and pass the shared stair
-- postpass, rather than merely existing as parsed catalog metadata.
local function generated_layouts(ctx)
    local parents = {
        "layout_pan_divisions_a",
        "layout_pan_divisions_b",
    }

    for _ = 1, 8 do
        for _, id in ipairs(parents) do
            local definition = layout_catalog.get(id)
            local result = layout_catalog.execute(ctx, definition,
                branches.BRANCH_PANDEMONIUM, 1)

            harness.equal(result.id, id, "generated Pan layout ID")
            harness.equal(#result.rows, 70, "full-height Pan layout")
            harness.truthy(#result.records > 0,
                "Pan layout retains authored effect records")
        end
    end
end

-- Exercise both source parents using the same production catalogs and
-- layout entry point that later branch generation will call.
function test.run(ctx)
    vault_catalog.load()
    layout_catalog.load()
    family_contract(ctx)
    generated_layouts(ctx)
end

return test

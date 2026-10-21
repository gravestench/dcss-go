-- A Shoals vault must replace the base island elevations under its cells.
-- Keyed DES height and immunity declarations win after terrain painting.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local heights = require("constants.shoals_heights")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local properties = require("constants.vault_properties")
local overlay = require("policy.generation.shoals_heights")

local test = {}

-- Give the overlay real builder coordinates but no random generation so the
-- assertions isolate what happens after a DES map is already placed.
local function floor_fixture()
    local ctx = {}
    local builder = grid.new(ctx)
    local heightmap = {}

    for y = 1, grid.height do
        heightmap[y] = {}

        for x = 1, grid.width do
            heightmap[y][x] = heights.DEEP
        end
    end

    builder:set(10, 10, ".")
    builder:set(11, 10, "W")
    builder:set(12, 10, ".")

    return {
        branch_id = branches.BRANCH_SHOALS,
        layout = {
            builder = builder,
            heightmap = heightmap,
        },
        extra = {
            {
                occupied = {
                    { x = 10, y = 10 },
                    { x = 11, y = 10 },
                    { x = 12, y = 10 },
                },
            },
        },
        records = {
            {
                kind = effects.PROPERTY,
                directive = directives.FHEIGHT,
                identity = "15",
                x = 10,
                y = 10,
            },
            {
                kind = effects.PROPERTY,
                directive = directives.FHEIGHT,
                identity = "15",
                x = 12,
                y = 10,
            },
            {
                kind = effects.PROPERTY,
                directive = directives.KPROP,
                identity = properties.NO_TIDE,
                x = 12,
                y = 10,
            },
        },
    }
end

-- The persisted heightmap, not merely a separate property record, must
-- expose the finished elevation to the live tide system.
function test.run()
    local floor = floor_fixture()
    local result = overlay.overlay(floor)

    harness.equal(result[11][11], 15, "FHEIGHT overrides base sea")
    harness.equal(result[11][12], heights.SHALLOW,
        "authored shallow water overrides base sea")
    harness.equal(result[11][13], heights.TIDE_IMMUNE,
        "no_tide wins over FHEIGHT")
    harness.equal(result[10][10], heights.DEEP,
        "unpainted sea keeps its original height")
end

return test

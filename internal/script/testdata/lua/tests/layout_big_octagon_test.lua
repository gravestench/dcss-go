-- The octagon has authored pillar rings and six placed stairs. Tests use
-- its actual DES hook and production stair postpass instead of a mock map.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layout = require("policy.generation.layouts.layout_big_octagon")
local stairs = require("policy.generation.layouts.stairs")
local grid = require("policy.generation.grid")
local glyphs = require("constants.vault_glyphs")
local harness = require("tests.harness")

local test = {}

-- A deterministic varied source exercises shape, ring, and stair draws
-- while still using the grid's unbiased bounded random routine.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "octagon layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- A centered octagon needs its clipped corners, interior pillars, and all
-- three authored up/down links connected in the final playable region.
local function source_octagon(seed)
    local result = layout.layout_big_octagon({
        ctx = random_context(seed),
        branch = "D",
        depth = 9,
    })
    local authored_up = 0
    local authored_down = 0

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local glyph = result.builder:cell(x, y)

            if glyphs.up[glyph] then
                authored_up = authored_up + 1
            elseif glyphs.down[glyph] then
                authored_down = authored_down + 1
            end
        end
    end

    harness.truthy(layout.validate(result), "source open-area threshold")
    harness.equal(result.builder:cell(10, 10), "#", "octagon corner clipped")
    harness.equal(authored_up, 3, "three authored up stairs")
    harness.equal(authored_down, 3, "three authored down stairs")
    harness.equal(#stairs.complete(result.builder), 3, "octagon stair pairs")
    harness.equal(#result.builder:rows(), grid.height, "octagon height")
end

-- Check the source hook reference before trying several ring shapes.
function test.run()
    local path = "vaults/layout/layout_big_octagon.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)
    source_octagon(1)
    source_octagon(47)
    source_octagon(891)
end

return test

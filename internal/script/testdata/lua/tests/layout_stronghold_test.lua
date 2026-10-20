-- Stronghold clusters cells into fortified building groups and leaves
-- ungrouped cells as streets dotted with small rock blocks.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layout = require("policy.generation.layouts.layout_stronghold")
local stairs = require("policy.generation.layouts.stairs")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")

local test = {}

-- Use several deterministic streams without shadowing the production
-- bounded RNG implementation.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "Stronghold layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Building clusters should occupy multiple source cells, while the
-- connected streets leave room for shared stair placement.
local function source_stronghold(seed)
    local result = layout.layout_stronghold({
        ctx = random_context(seed),
        branch = "D",
        depth = 9,
    })
    local buildings = 0
    local floor = 0

    for _, cell in ipairs(result.cells) do
        if cell.building then
            buildings = buildings + 1
        end
    end

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if result.builder:cell(x, y) == "." then
                floor = floor + 1
            end
        end
    end

    harness.truthy(buildings >= 4, "source building cells")
    harness.truthy(floor > 300, "connected Stronghold area")
    harness.equal(#stairs.complete(result.builder), 3,
        "Stronghold stair pairs")
    features.decode_source_rows(result.builder:rows())
end

-- Resolve the committed DES hook and inspect more than one cell grouping.
function test.run()
    local path = "vaults/layout/layout_stronghold.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)
    source_stronghold(1)
    source_stronghold(47)
end

return test

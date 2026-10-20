-- Gridville grows connected building groups over source omnigrid cells.
-- Its test uses the committed DES hook, real grid, and shared stair pass.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layout = require("policy.generation.layouts.layout_gridville")
local stairs = require("policy.generation.layouts.stairs")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")

local test = {}

-- Different seeds exercise open/closed city choices without copying any
-- production tile or room schema into the test fixture.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "Gridville stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- City groups must carve real buildings among floor and rock cells while
-- leaving one playable region for the generic exit placement.
local function source_gridville(seed)
    local result = layout.layout_gridville({
        ctx = random_context(seed),
        branch = "D",
        depth = 9,
    })
    local city = 0
    local floor = 0

    for _, cell in ipairs(result.cells) do
        if cell.tile == "city" then
            city = city + 1
        end
    end

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if result.builder:cell(x, y) == "." then
                floor = floor + 1
            end
        end
    end

    harness.truthy(city > 0, "source city cells, seed " .. seed)
    -- The source's closed variant begins with one building and can retain
    -- only a small connected block; open variants must span a larger floor.
    local minimum_floor = result.open and 100 or 10

    harness.truthy(floor > minimum_floor,
        "Gridville playable floor, seed " .. seed .. ", count " .. floor)
    harness.equal(#stairs.complete(result.builder), 3, "Gridville stair pairs")
    features.decode_source_rows(result.builder:rows())
end

-- Resolve the source hook and inspect multiple generated city maps.
function test.run()
    local path = "vaults/layout/layout_gridville.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)
    source_gridville(1)
    source_gridville(47)
    source_gridville(891)
end

return test

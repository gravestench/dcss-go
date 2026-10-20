-- Irregular City uses the source's orthogonal wall divisions instead of
-- replacing its city hook with an ordinary rectangular room generator.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local irregular_box = require("policy.generation.layouts.irregular_box")
local layout = require("policy.generation.layouts.layout_irregular_city")
local stairs = require("policy.generation.layouts.stairs")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")

local test = {}

-- A varied deterministic stream exercises the real bounded-draw path.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "Irregular City stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- The wall helper must make a hollow, irregular footprint with doors that
-- can be decoded by the same terrain reader used by live generation.
local function source_box()
    local builder = grid.new(random_context(17))

    irregular_box.carve(builder, {
        x1 = 8,
        y1 = 8,
        x2 = 58,
        y2 = 48,
        div_x = 8,
        div_y = 7,
        in_x = 7,
        in_y = 6,
        doors = 4,
        wall = "c",
        floor = ".",
    })

    local floor = 0
    local walls = 0
    local doors = 0

    for y = 8, 48 do
        for x = 8, 58 do
            local glyph = builder:cell(x, y)

            if glyph == "." then
                floor = floor + 1
            elseif glyph == "c" then
                walls = walls + 1
            elseif glyph == "+" then
                doors = doors + 1
            end
        end
    end

    harness.truthy(floor > 500, "irregular box interior")
    harness.truthy(walls > 100, "divided outer wall")
    harness.equal(doors, 4, "requested door count")
    features.decode_source_rows(builder:rows())
end

-- The named DES hook should leave a large central street area and add
-- smaller non-overlapping buildings with source wall materials and doors.
local function source_city(seed)
    local result = layout.layout_irregular_city({
        ctx = random_context(seed),
        branch = "D",
        depth = 9,
    })
    local floor = 0

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if result.builder:cell(x, y) == "." then
                floor = floor + 1
            end
        end
    end

    harness.truthy(#result.rooms >= 5, "source city buildings")
    harness.truthy(floor > 200, "connected city floor")
    harness.equal(#stairs.complete(result.builder), 3, "city stair pairs")
    features.decode_source_rows(result.builder:rows())
end

-- Resolve the checked-in hook before exercising both its primitive and
-- complete layout through several independent seeds.
function test.run()
    local path = "vaults/layout/layout_irregular_city.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)
    source_box()
    source_city(1)
    source_city(47)
    source_city(891)
end

return test

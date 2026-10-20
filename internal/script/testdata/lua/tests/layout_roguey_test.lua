-- The source Roguey layout is a grid of variably missing rooms, linked by
-- bent corridors and occasional miniature mazes.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layout = require("policy.generation.layouts.layout_roguey")
local stairs = require("policy.generation.layouts.stairs")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")

local test = {}

-- Use the production bounded draw with a deterministic varied stream so
-- room omission and mazes differ between seeds.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "Roguey layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Each generated Roguey floor must carve multiple rooms and a reachable
-- primary region, not silently reuse the basic stair-trail algorithm.
local function source_roguey(seed)
    local result = layout.layout_roguey({
        ctx = random_context(seed),
        branch = "D",
        depth = 9,
    })
    local present = 0
    local floor_count = 0

    for _, room in ipairs(result.rooms) do
        if room.present then
            present = present + 1
        end
    end

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if result.builder:cell(x, y) == "." then
                floor_count = floor_count + 1
            end
        end
    end

    harness.truthy(present >= 3, "multiple source rooms present")
    harness.truthy(floor_count > 100, "Roguey playable area")
    harness.equal(#stairs.complete(result.builder), 3, "Roguey stair pairs")
end

-- The source DES hook must resolve to this module before generation runs.
function test.run()
    local path = "vaults/layout/layout_roguey.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)
    source_roguey(1)
    source_roguey(47)
    source_roguey(891)
end

return test

-- Small and long grids run through their checked-in DES hooks and the same
-- grid/stair owners used by live Dungeon generation.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local stairs = require("policy.generation.layouts.stairs")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")

local test = {}

-- A varied deterministic stream keeps the production bounded draw active
-- without relying on the game's full Go world fixture.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "grid layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Both subdivisions must produce a mostly open but divided grid rather
-- than falling back to the basic stair trails or one featureless room.
local function source_grid(id, seed, depth)
    local path = "vaults/layout/" .. id .. ".des"
    local definition = des.parse(path, mod.read(path))
    local layout = require("policy.generation.layouts." .. id)

    hooks.validate(definition)

    local result = layout[id]({
        ctx = random_context(seed),
        branch = "D",
        depth = depth,
    })
    local floor_count = 0
    local wall_count = 0

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local glyph = result.builder:cell(x, y)

            if glyph == "." then
                floor_count = floor_count + 1
            elseif glyph == "#" then
                wall_count = wall_count + 1
            end
        end
    end

    harness.truthy(floor_count > 100, id .. " floor area")
    harness.truthy(wall_count > 100, id .. " divided wall area")
    harness.equal(#stairs.complete(result.builder), 3, id .. " stairs")
end

-- Run both grid styles with several seeds to cover jitter and exterior
-- corridors without a broad repository test after each algorithm tweak.
function test.run()
    for _, id in ipairs({ "layout_small_grid", "layout_long_grid" }) do
        for _, seed in ipairs({ 1, 47, 891 }) do
            source_grid(id, seed, 9)
            source_grid(id, seed, 15)
        end
    end
end

return test

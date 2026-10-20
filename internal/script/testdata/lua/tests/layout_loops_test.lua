-- All three source Loop layouts share divided lines, corner positions, and
-- room shapes; this test exercises their checked-in DES hooks together.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local ring = require("policy.generation.layouts.layout_loops_ring")
local cross = require("policy.generation.layouts.layout_loops_cross")
local corners = require("policy.generation.layouts.layout_loops_corners")
local stairs = require("policy.generation.layouts.stairs")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")

local test = {}

-- Use the same bounded layout RNG as the production builder with varied
-- deterministic starting states for each family member.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "loop layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Count usable cells after each hook's own shared connectivity cleanup.
local function floor_count(builder)
    local count = 0

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if builder:cell(x, y) == "." then
                count = count + 1
            end
        end
    end

    return count
end

-- A forced layout ID must execute its real loop policy and leave enough
-- connected floor for the shared source stair pass.
local function source_loop(name, module, seed)
    local path = "vaults/layout/" .. name .. ".des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)

    local result = module[name]({
        ctx = random_context(seed),
        branch = "D",
        depth = 9,
    })

    harness.truthy(result.loop_count > 3, name .. " source loop count")
    if name == "layout_loops_cross" then
        harness.equal(result.builder:cell(grid.width / 2,
            grid.height / 2), ".", "central cross room")
    end
    harness.truthy(floor_count(result.builder) > 80,
        name .. " connected loop area")
    harness.equal(#stairs.complete(result.builder), 3,
        name .. " stair pairs")
    features.decode_source_rows(result.builder:rows())
end

-- Cover the ring, connected central cross, and four-corner structure.
function test.run()
    for _, seed in ipairs({ 1, 47, 891 }) do
        source_loop("layout_loops_ring", ring, seed)
        source_loop("layout_loops_cross", cross, seed)
        source_loop("layout_loops_corners", corners, seed)
    end
end

return test

-- Cave Pools uses the source spotty cave seed, then seeds and grows pools
-- over its floor. The test exercises its checked-in DES hook and real grid.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layout = require("policy.generation.layouts.layout_cave_pools")
local stairs = require("policy.generation.layouts.stairs")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")

local test = {}

-- Keep gameplay draws deterministic while retaining the grid's actual
-- bounded uint64 implementation for every source random choice.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "cave pools stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Source Dungeon weights fill pools with floor or rock; water/lava enter
-- only the Depths branch. All generated variants need a playable region.
local function source_cave(seed, branch, depth, absolute_depth)
    local result = layout.layout_cave_pools({
        ctx = random_context(seed),
        branch = branch,
        depth = depth,
        absolute_depth = absolute_depth or depth,
    })
    local count = {
        ["."] = 0,
        ["#"] = 0,
        w = 0,
        l = 0,
    }

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local glyph = result.builder:cell(x, y)

            if count[glyph] then
                count[glyph] = count[glyph] + 1
            end
        end
    end

    harness.truthy(count["."] > 100, "cave floor area")
    harness.truthy(count["#"] > 100, "cave rock area")
    harness.equal(#stairs.complete(result.builder), 3, "cave stair pairs")

    if branch == "D" then
        harness.equal(count.w + count.l, 0, "Dungeon source pool contents")
    else
        local contents = result.pool_contents[3]

        harness.truthy(contents.glyph == "w" or contents.glyph == "l",
            "Depths chooses one liquid pool material")
        harness.truthy(contents.weight > 0, "Depths has a positive liquid weight")
    end
end

-- Check the source hook and multiple depths in the currently generated
-- Dungeon; Depths exercises its distinct pool-content branch.
function test.run()
    local path = "vaults/layout/layout_cave_pools.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)
    source_cave(1, "D", 4)
    source_cave(47, "D", 15)
    source_cave(1, "Depths", 3, 18)
end

return test

-- The source procedural cave family uses shared noise functions but two
-- separate threshold policies: layered narrow caves and connected pods.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layer = require("policy.generation.layouts.layout_layer_cave")
local pods = require("policy.generation.layouts.layout_cave_pods")
local stairs = require("policy.generation.layouts.stairs")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")

local test = {}

-- Exercise source layout draws through the production bounded RNG.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "cave layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Count real walkable cells rather than accepting any nonempty source row.
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

-- Every source hook should make a cave large enough for normal Dungeon
-- travel, then the common stair pass must connect all six exits.
local function source_cave(name, module, seed, branch)
    local path = "vaults/layout/" .. name .. ".des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)

    local result = module[name]({
        ctx = random_context(seed),
        branch = branch or "D",
        depth = 9,
    })

    harness.truthy(floor_count(result.builder) > 560,
        name .. " source minimum floor area")
    harness.equal(#stairs.complete(result.builder), 3,
        name .. " connected stair pairs")
    features.decode_source_rows(result.builder:rows())
end

-- Both layout hooks share noise primitives but retain their own source
-- thresholds; several seeds cover the optional overlay in Layer Cave.
function test.run()
    source_cave("layout_layer_cave", layer, 1)
    source_cave("layout_layer_cave", layer, 47)
    source_cave("layout_cave_pods", pods, 1)
    source_cave("layout_cave_pods", pods, 47)
    source_cave("layout_cave_pods", pods, 91, "Snake")
end

return test

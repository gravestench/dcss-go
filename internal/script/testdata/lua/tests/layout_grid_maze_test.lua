-- Grid Maze subdivides a floor into cells and connects them with open
-- borders or doors before the shared stair postpass chooses exits.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layout = require("policy.generation.layouts.layout_grid_maze")
local stairs = require("policy.generation.layouts.stairs")
local features = require("content.terrain_features")
local harness = require("tests.harness")

local test = {}

-- Varied deterministic words exercise source subdivision and connection
-- draws through the production grid RNG without another maze implementation.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "grid maze stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- D always uses the source thin-wall variant. Its connected cell graph
-- must survive painting and leave enough floor for three stair pairs.
local function source_maze(seed, branch)
    local result = layout.layout_grid_maze({
        ctx = random_context(seed),
        branch = branch,
        depth = 9,
    })

    harness.truthy(#result.cells > 10, "subdivided source cells")
    harness.truthy(#result.edges >= #result.cells - 1,
        "neighbor graph can connect all cells")
    harness.equal(#stairs.complete(result.builder), 3, "maze stair pairs")
    features.decode_source_rows(result.builder:rows())
end

-- Resolve the checked-in hook before testing multiple generated mazes.
function test.run()
    local path = "vaults/layout/layout_grid_maze.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)
    source_maze(1, "D")
    source_maze(47, "D")
    source_maze(891, "D")
    source_maze(47, "Snake")
    source_maze(891, "Tar")
end

return test

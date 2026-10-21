-- The source chaotic city is a branch-weighted procedural layout. Test its
-- committed DES declaration together with the named Lua terrain painter.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layout = require("policy.generation.layouts.layout_chaotic_city")
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local depth = require("policy.generation.vaults.depth")
local stairs = require("policy.generation.layouts.stairs")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

-- Independent seeded contexts vary box sites while production grid:roll
-- still consumes the real layout stream and bounds its own draws.
local function random_context(seed)
    local state = seed
    local context = {}

    -- Use the engine's stream name; this catches accidental global draws.
    function context:random_u64(stream)
        harness.equal(stream, "layout", "chaotic city stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- The source starts with a broad open square and admits only separated
-- buildings. A box should never seal the entire street network.
local function generated_city(branch, seed)
    local result = layout.layout_chaotic_city({
        ctx = random_context(seed),
        branch = branch,
        depth = 2,
    })
    local floor = 0
    local walls = 0

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local glyph = result.builder:cell(x, y)

            if glyph == "." then
                floor = floor + 1
            elseif glyph == "#" or glyph == "c" or glyph == "v" then
                walls = walls + 1
            end
        end
    end

    harness.truthy(#result.boxes >= 3, "separate city buildings")
    harness.truthy(floor > 400, "open city streets")
    harness.truthy(walls > 100, "building walls")
    harness.equal(#stairs.complete(result.builder), 3,
        "connected chaotic city stair pairs")
    features.decode_source_rows(result.builder:rows())
end

-- The production catalog must actually select this source metadata for
-- its two branches and finish connected stairs after the named hook.
local function catalog_city(branch_id, expected_weight)
    local definition = catalog.get("layout_chaotic_city")
    local result = catalog.execute(random_context(317), definition,
        branch_id, 1)

    harness.equal(weight.for_branch(definition, branch_id),
        expected_weight, "source chaotic city branch weight")
    harness.truthy(depth.eligible(definition, branch_id, 1, 3),
        "source chaotic city branch eligibility")
    harness.equal(result.id, "layout_chaotic_city", "selected layout ID")
    harness.truthy(#result.stairs >= 3, "catalog connects city stairs")
    features.decode_source_rows(result.rows)
end

-- The `.des` file remains authoritative for branch selection and hook
-- binding; Lair and Crypt both need their source-weighted version.
function test.run()
    local path = "vaults/layout/layout_chaotic_city.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)
    generated_city(branches.BRANCH_LAIR, 1)
    generated_city(branches.BRANCH_CRYPT, 47)
    catalog.load()
    catalog_city(branches.BRANCH_LAIR, 10)
    catalog_city(branches.BRANCH_CRYPT, 15)
end

return test

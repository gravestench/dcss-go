-- Two source layouts share omnigrid cells but produce different terrain:
-- Growth spreads connected wall groups; Gridlike joins rooms by corridors.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local effects = require("constants.vault_effects")
local monsters = require("ids.monsters")
local features = require("content.terrain_features")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

local growth_branches = {
    {
        id = branches.BRANCH_LAIR,
        weight = 2,
    },
    {
        id = branches.BRANCH_ZOT,
        weight = 5,
    },
    {
        id = branches.BRANCH_PANDEMONIUM,
        weight = 10,
    },
}

local gridlike_branches = {
    {
        id = branches.BRANCH_ELF,
        weight = 20,
    },
    {
        id = branches.BRANCH_LAIR,
        weight = 10,
    },
    {
        id = branches.BRANCH_SNAKE,
        weight = 10,
    },
    {
        id = branches.BRANCH_CRYPT,
        weight = 15,
    },
    {
        id = branches.BRANCH_DEPTHS,
        weight = 20,
    },
    {
        id = branches.BRANCH_ZOT,
        weight = 20,
    },
    {
        id = branches.BRANCH_PANDEMONIUM,
        weight = 15,
    },
}

-- Feed the real bounded layout draw several reproducible stream values.
-- This fixture never substitutes for production grid:roll behavior.
local function context_for(seed)
    local state = seed
    local context = {}

    -- Layout generation must consume only its named random stream.
    function context:random_u64(stream)
        harness.equal(stream, "layout", "cellular layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Inspect the completed terrain rather than only the registered hook.
-- Both source families need walkable area amid a substantial rock body.
local function counts(result)
    local floor = 0
    local walls = 0

    for _, row in ipairs(result.rows) do
        for glyph in row:gmatch(".") do
            if glyph == "." then
                floor = floor + 1
            elseif glyph == "#" or glyph == "c" or glyph == "v" then
                walls = walls + 1
            end
        end
    end

    return floor, walls
end

-- All three source branches must produce wall islands and connected
-- stairs through the catalog's normal postpass.
local function check_growth(branch, seed)
    local definition = catalog.get("layout_cellular_growth")
    local result = catalog.execute(context_for(seed), definition,
        branch.id, 2)
    local floor, walls = counts(result)

    harness.equal(weight.for_branch(definition, branch.id),
        branch.weight, "Growth source branch weight")
    harness.equal(result.id, definition.id, "Growth selected identity")
    harness.truthy(floor > 150, "Growth walkable cells")
    harness.truthy(walls > 500, "Growth wall field")
    harness.truthy(#result.stairs >= 3, "Growth connected stairs")
    features.decode_source_rows(result.rows)
end

-- Gridlike's seven eligible branches must all execute the same source
-- tiling policy with branch-owned corridor and room variants.
local function check_gridlike(branch, seed)
    local definition = catalog.get("layout_gridlike")
    local result = catalog.execute(context_for(seed), definition,
        branch.id, 2)
    local floor, walls = counts(result)

    harness.equal(weight.for_branch(definition, branch.id),
        branch.weight, "Gridlike source branch weight")
    harness.equal(result.id, definition.id, "Gridlike selected identity")
    harness.truthy(floor > 100, "Gridlike walkable rooms")
    harness.truthy(walls > 200, "Gridlike partition walls")
    harness.truthy(#result.stairs >= 3, "Gridlike connected stairs")
    features.decode_source_rows(result.rows)

    local special = 0
    local plants = 0

    for _, record in ipairs(result.records or {}) do
        if record.kind == effects.PROPERTY or
            record.kind == effects.MASK or
            record.kind == effects.MONSTER then
            special = special + 1
        end

        if record.kind == effects.MONSTER then
            harness.equal(record.arguments.kind_id,
                monsters.MONS_PLANT, "source plant fill ID")
            plants = plants + 1
        end
    end

    return special, plants
end

-- Discover both committed DES files through the actual layered catalog.
function test.run()
    catalog.load()

    for index, branch in ipairs(growth_branches) do
        check_growth(branch, index * 113)
    end

    local special = 0
    local plants = 0

    for index, branch in ipairs(gridlike_branches) do
        local effects_count, plant_count = check_gridlike(branch,
            index * 211)

        special = special + effects_count
        plants = plants + plant_count
    end

    harness.truthy(special > 0,
        "Gridlike keeps keyed fill properties and monsters as records")
    harness.truthy(plants > 0,
        "Gridlike emits the source plant monster slot")
end

return test

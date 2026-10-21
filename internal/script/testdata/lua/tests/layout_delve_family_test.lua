-- The four weighted source delve maps must be executable through the same
-- DES catalog that selects real branch floors. These assertions inspect the
-- final terrain and stairs, not a substitute copy of the carving rules.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local features = require("content.terrain_features")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")
local properties = require("constants.vault_properties")

local test = {}

local cases = {
    {
        id = "layout_twisted_cross",
        branch = branches.BRANCH_DEPTHS,
        weight = 5,
    },
    {
        id = "layout_twisted_circle",
        branch = branches.BRANCH_ZOT,
        weight = 10,
    },
    {
        id = "layout_spider_delve",
        branch = branches.BRANCH_SPIDER,
        weight = 25,
    },
    {
        id = "layout_cocytus_delve",
        branch = branches.BRANCH_COCYTUS,
        weight = 10,
    },
}

-- Use the production layout random stream with a reproducible source of bits.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "delve layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Every selected layout needs a substantial carved region and exits that
-- the ordinary stair postpass can reach without traversing deep water.
local function check(case, seed)
    local definition = catalog.get(case.id)
    local ok, result = pcall(catalog.execute, context_for(seed),
        definition, case.branch, 2)

    if not ok then
        error(case.id .. ": " .. result)
    end

    local floor = 0
    local wall = 0

    harness.equal(weight.for_branch(definition, case.branch),
        case.weight, case.id .. " source weight")
    harness.equal(result.id, case.id, "selected delve identity")

    for _, row in ipairs(result.rows) do
        for glyph in row:gmatch(".") do
            if glyph == "." or glyph == "_" then
                floor = floor + 1
            elseif glyph == "#" or glyph == "c" or glyph == "v" then
                wall = wall + 1
            end
        end
    end

    harness.truthy(floor > 100, case.id .. " carved floor")
    harness.truthy(wall > 100, case.id .. " rock body")
    harness.truthy(#result.stairs >= 2, case.id .. " connected stairs")
    features.decode_source_rows(result.rows)

    return result
end

-- Cocytus puts teleport restriction on side passages because those can be
-- separated from the stair route by deep water.
local function check_cocytus(result)
    local restricted = 0

    for _, record in ipairs(result.records or {}) do
        if record.identity == properties.NO_TELE_INTO then
            restricted = restricted + 1
        end
    end

    harness.truthy(restricted > 0, "Cocytus side-area teleport restriction")
end

-- Execute each committed source definition through its live branch rules.
function test.run()
    catalog.load()

    for index, case in ipairs(cases) do
        local result = check(case, index * 157)

        if case.id == "layout_twisted_circle" then
            harness.truthy(result.room_count > 0,
                "Zot circle has rendered rooms")
        elseif case.id == "layout_cocytus_delve" then
            check_cocytus(result)
        end
    end
end

return test

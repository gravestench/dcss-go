-- Cave Shapes combines a source shape and cave edge field; Gehenna Lava
-- Caves grades simplex noise into rock, lava, and walkable channels.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

-- Supply reproducible high and low RNG halves to production layout hooks.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "noise cave layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- The hooked map must preserve its source branch clauses and produce
-- enough connected floor for paired stairs across several seeded draws.
local function check(id, branch_id, expected_weight)
    local definition = catalog.get(id)
    local floor = 0
    local lava = 0
    local stone = 0

    harness.equal(weight.for_branch(definition, branch_id),
        expected_weight, id .. " source branch weight")
    harness.truthy(depth.eligible(definition, branch_id, 1, 7),
        id .. " source branch eligibility")
    harness.falsy(depth.eligible(definition,
        branches.BRANCH_DUNGEON, 10, 15),
        id .. " is not a Dungeon layout")

    for seed = 1, 5 do
        local result = catalog.execute(context_for(seed * 157),
            definition, branch_id, seed)

        harness.equal(result.id, id, "executed source layout ID")
        harness.equal(#result.rows, 70, "layout height")
        harness.equal(#result.rows[1], 80, "layout width")
        harness.truthy(#result.stairs >= 3,
            "layout has connected ordinary stairs")

        for _, row in ipairs(result.rows) do
            for glyph in row:gmatch(".") do
                if glyph == "." then
                    floor = floor + 1
                elseif glyph == "l" then
                    lava = lava + 1
                elseif glyph == "c" then
                    stone = stone + 1
                end
            end
        end
    end

    harness.truthy(floor > 700,
        id .. " retains source cave floor")

    if id == "layout_gehenna_lava_caves" then
        harness.truthy(lava > 100,
            "Gehenna noise grades into lava")
        harness.truthy(stone > 0,
            "Gehenna caves reuse source stone buildings")
    end
end

-- Snake and Depths have different Cave Shapes weights, but share the
-- geometry hook and source depth-independent shape family.
function test.run()
    check("layout_cave_shapes", branches.BRANCH_LAIR, 3)
    check("layout_cave_shapes", branches.BRANCH_SNAKE, 5)
    check("layout_cave_shapes", branches.BRANCH_DEPTHS, 10)
    check("layout_gehenna_lava_caves", branches.BRANCH_GEHENNA, 20)
end

return test

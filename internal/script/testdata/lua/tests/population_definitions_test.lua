-- Population draws use stable monster IDs, independent of Lua file discovery.

local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local pool = require("policy.population.pool")
local roster = require("policy.population.roster")
local validation = require("content.validation")

local test = {}

local generated_scenario = "generated-dungeon-basic-v1"
local fixed_scenario = "fixed-dungeon-population-v1"

local fixed_expected = {
    monsters.MONS_RAT,
    monsters.MONS_FRILLED_LIZARD,
    monsters.MONS_GIANT_COCKROACH,
    monsters.MONS_QUOKKA,
    monsters.MONS_JACKAL,
    monsters.MONS_WORM,
    monsters.MONS_ADDER,
}

table.sort(fixed_expected)

-- Source rarity remains intact even though the picker now uses stable IDs.
local function source_pool_uses_stable_ids()
    local allowed = roster.allowed(generated_scenario)
    local first, first_total = pool.at_depth(1, allowed, generated_scenario)
    local second, second_total = pool.at_depth(2, allowed, generated_scenario)

    harness.truthy(#first > 10 and first_total > 0,
        "D:1 admits more than the old twelve-monster roster")
    harness.truthy(#second > 12 and second_total > 0,
        "D:2 admits all source rows in range")

    for index = 2, #second do
        harness.truthy(second[index - 1].id <= second[index].id,
            "D:2 picker order follows stable monster IDs")
    end

    for _, row in ipairs(second) do
        if row.id == monsters.MONS_DART_SLUG then
            harness.equal(row.weight, 882000,
                "dart slug source rarity survives the move")

            return
        end
    end

    error("D:2 pool lost the dart slug")
end

-- Fixed population rows have their own counts and weights at D:1 and D:2.
local function fixed_pool_unchanged()
    local allowed = roster.allowed(fixed_scenario)
    local first, first_total = pool.at_depth(1, allowed, fixed_scenario)
    local second, second_total = pool.at_depth(2, allowed, fixed_scenario)

    harness.equal(#first, 5, "fixed D:1 source row count")
    harness.equal(#second, 7, "fixed D:2 source row count")
    harness.equal(first_total, 7156800, "fixed D:1 source total weight")
    harness.equal(second_total, 10936800, "fixed D:2 source total weight")

    for index, monster_id in ipairs(fixed_expected) do
        harness.equal(second[index].id, monster_id,
            "fixed D:2 ID-sorted picker order at row " .. index)
    end
end

-- Every population reference must resolve to an active monster definition.
local function rows_belong_to_monsters()
    local jackal = catalog.get(categories.MONSTERS, monsters.MONS_JACKAL)

    harness.equal(#(jackal.population or {}), 2,
        "jackal owns both source population rows")
    harness.falsy(jackal.population[1].source_order,
        "jackal row no longer needs a global source position")
    harness.falsy(jackal.population[2].source_order,
        "second jackal row no longer needs a global source position")
end

-- A mod cannot reintroduce a position that changes picker order outside its
-- monster definition. Two local rows keep their order within that definition.
local function source_order_is_rejected()
    local jackal = catalog.get(categories.MONSTERS, monsters.MONS_JACKAL)
    local second = jackal.population[2]
    local original = second.source_order

    second.source_order = 13
    local valid, reason = pcall(validation.population_rows, { jackal })
    second.source_order = original

    harness.falsy(valid, "source order metadata was accepted")
    harness.truthy(reason:find("source_order", 1, true),
        "source order error does not name the removed field")
end

-- A generated Dungeon run must draw every committed source population row.
-- Mod authors should not have to add a monster ID to a second roster list.
local function generated_roster_covers_source_dungeon()
    local allowed = roster.allowed(generated_scenario)

    for _, monster in ipairs(catalog.all(categories.MONSTERS)) do
        for _, row in ipairs(monster.population or {}) do
            if row.scenario_id == nil then
                harness.truthy(allowed[monster.id],
                    monster.id .. " has a source row but is not in the roster")
            end
        end
    end

    for depth = 1, 15 do
        local rows, total = pool.at_depth(depth, allowed, generated_scenario)

        harness.truthy(#rows > 0 and total > 0,
            "Dungeon:" .. depth .. " has no population")
    end
end

-- Reject an unknown depth curve at validation time so runtime population
-- selection cannot apply an undefined weight formula.
local function invalid_curve_is_rejected()
    local rat = catalog.get(categories.MONSTERS, monsters.MONS_RAT)
    local row = rat.population[1]
    local original = row.curve

    row.curve = "UNKNOWN_CURVE"
    local valid, reason = pcall(validation.population_rows, { rat })
    row.curve = original

    harness.falsy(valid, "invalid population curve was accepted")
    harness.truthy(reason:find("population curve", 1, true),
        "curve error does not name the rule")
end

-- Check source and fixed pools plus row validation, because every generated
-- monster choice depends on a well-formed ordered population row set.
function test.run()
    source_pool_uses_stable_ids()
    fixed_pool_unchanged()
    rows_belong_to_monsters()
    source_order_is_rejected()
    generated_roster_covers_source_dungeon()
    invalid_curve_is_rejected()
end

return test

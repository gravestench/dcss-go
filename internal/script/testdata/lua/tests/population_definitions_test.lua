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

local expected = {
    monsters.MONS_BAT,
    monsters.MONS_RAT,
    monsters.MONS_FRILLED_LIZARD,
    monsters.MONS_BALL_PYTHON,
    monsters.MONS_GIANT_COCKROACH,
    monsters.MONS_HOBGOBLIN,
    monsters.MONS_ENDOPLASM,
    monsters.MONS_DART_SLUG,
    monsters.MONS_QUOKKA,
    monsters.MONS_JACKAL,
    monsters.MONS_WORM,
    monsters.MONS_ADDER,
}

local fixed_expected = {
    monsters.MONS_RAT,
    monsters.MONS_FRILLED_LIZARD,
    monsters.MONS_GIANT_COCKROACH,
    monsters.MONS_QUOKKA,
    monsters.MONS_JACKAL,
    monsters.MONS_WORM,
    monsters.MONS_ADDER,
}

local function source_pool_unchanged()
    local allowed = roster.allowed(generated_scenario)
    local first, first_total = pool.at_depth(1, allowed, generated_scenario)
    local second, second_total = pool.at_depth(2, allowed, generated_scenario)

    harness.equal(#first, 10, "D:1 source row count")
    harness.equal(#second, 12, "D:2 source row count")
    harness.equal(first_total, 18118800, "D:1 source total weight")
    harness.equal(second_total, 21898800, "D:2 source total weight")

    for index, monster_id in ipairs(expected) do
        harness.equal(second[index].id, monster_id,
            "D:2 source picker order at row " .. index)
    end

    harness.equal(second[8].weight, 882000,
        "dart slug source rarity survives the move")
end

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
            "fixed D:2 source picker order at row " .. index)
    end
end

local function rows_belong_to_monsters()
    local jackal = catalog.get(categories.MONSTERS, monsters.MONS_JACKAL)

    harness.equal(#(jackal.population or {}), 2,
        "jackal owns both source population rows")
    harness.equal(jackal.population[1].source_order, 12,
        "jackal row keeps source picker order")
    harness.equal(jackal.population[2].source_order, 13,
        "second jackal row remains distinct")
end

local function invalid_source_order_is_rejected()
    local jackal = catalog.get(categories.MONSTERS, monsters.MONS_JACKAL)
    local second = jackal.population[2]
    local original = second.source_order

    second.source_order = jackal.population[1].source_order
    local valid, reason = pcall(validation.population_rows, { jackal })
    second.source_order = original

    harness.falsy(valid, "duplicate source order was accepted")
    harness.truthy(reason:find("duplicates", 1, true),
        "duplicate order error does not name the rule")
end

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

function test.run()
    source_pool_unchanged()
    fixed_pool_unchanged()
    rows_belong_to_monsters()
    invalid_source_order_is_rejected()
    invalid_curve_is_rejected()
end

return test

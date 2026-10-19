-- Test Moss adds a spawnable monster in the generated dungeon at depths one through three.

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_TEST_MOSS",
    name = "test moss",
    status = "defined",
    habitat_id = "HT_LAND",
    spellbook_id = "MST_NO_SPELLS",
    average_hp_10x = 25,
    speed = 10,
    hd = 1,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 3,
        },
    },
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
    },
    population = {
        {
            scenario_id = "generated-dungeon-basic-v1",
            min_depth = 1,
            max_depth = 3,
            rarity = 1000,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition

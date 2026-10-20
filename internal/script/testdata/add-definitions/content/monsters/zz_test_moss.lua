-- Test Moss adds a spawnable monster in the generated dungeon at depths one through three.

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_TEST_MOSS",
    name = "test moss",
    status = "defined",
    habitat_id = "HT_LAND",
    spellbook_id = spellbooks.MST_NO_SPELLS,
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
}

register.definition(categories.MONSTERS, definition)

return definition

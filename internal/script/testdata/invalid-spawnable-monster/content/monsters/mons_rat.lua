-- The overlaid rat is spawnable but lacks required placement metadata.

local categories = require("constants.catalog")

local definition = {
    id = "MONS_RAT",
    status = "defined",
    name = "broken rat",
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
}

register.definition(categories.MONSTERS, definition)

return definition

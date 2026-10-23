-- The Shining One is good; a living, non-demonic worshipper may join unless Lich Form temporarily intervenes.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.SHINING_ONE,
    name = "the Shining One",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 30,
    piety_mode = modes.ORDINARY,
    piety_decay_chance = 35,
    conduct_module = "policy.religion.conduct.shining_one",
    good = true,
}

register.definition(categories.GODS, definition)

return definition

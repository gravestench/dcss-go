-- Trog starts with ordinary piety and a focused behavior module that blocks
-- magic training while worship lasts. Later conduct rules handle spell use.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.TROG,
    name = "Trog",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 50,
    piety_mode = modes.ORDINARY,
    piety_decay_chance = 17,
    behavior_module = "policy.religion.gods.trog",
    conduct_module = "policy.religion.conduct.trog",
}

register.definition(categories.GODS, definition)

return definition

-- Dithmenos begins with ordinary piety; shadow passives activate in a later system.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.DITHMENOS,
    name = "Dithmenos",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 25,
    piety_mode = modes.ORDINARY,
    piety_decay_chance = 17,
    conduct_module = "policy.religion.conduct.dithmenos",
}

register.definition(categories.GODS, definition)

return definition

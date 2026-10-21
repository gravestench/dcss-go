-- Uskayaw starts at ordinary piety; combat-driven changes belong to its conduct rule.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.USKAYAW,
    name = "Uskayaw",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 25,
    piety_mode = modes.ORDINARY,
    behavior_module = "policy.religion.gods.uskayaw",
}

register.definition(categories.GODS, definition)

return definition

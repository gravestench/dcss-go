-- Gozag uses generated gold to price conversion and does not earn ordinary piety.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.GOZAG,
    name = "Gozag",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 50,
    piety_mode = modes.NONE,
    behavior_module = "policy.religion.gods.gozag",
}

register.definition(categories.GODS, definition)

return definition

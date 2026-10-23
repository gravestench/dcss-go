-- Ashenzari starts at two piety before curse progress can raise it.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.ASHENZARI,
    name = "Ashenzari",
    temple_eligible = true,
    starting_piety = 2,
    wrath_penance = 50,
    piety_mode = modes.ORDINARY,
    conduct_module = "policy.religion.conduct.ashenzari",
    behavior_module = "policy.religion.gods.ashenzari",
}

register.definition(categories.GODS, definition)

return definition

-- Zin is a good god: undead and demonic characters cannot join, and any active transformation blocks conversion.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.ZIN,
    name = "Zin",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 25,
    piety_mode = modes.ORDINARY,
    conduct_module = "policy.religion.conduct.zin",
    good = true,
    rejects_all_forms = true,
    behavior_module = "policy.religion.gods.zin",
}

register.definition(categories.GODS, definition)

return definition

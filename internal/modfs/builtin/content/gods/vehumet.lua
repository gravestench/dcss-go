-- Vehumet rewards learned magic, so an innate caster cannot join this god.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.VEHUMET,
    name = "Vehumet",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 25,
    piety_mode = modes.ORDINARY,
    conduct_module = "policy.religion.conduct.vehumet",
    rejects_innate_caster = true,
}

register.definition(categories.GODS, definition)

return definition

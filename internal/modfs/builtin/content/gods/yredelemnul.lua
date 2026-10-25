-- Yredelemnul relies on followers; the No Love mutation rules out this altar.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.YREDELEMNUL,
    name = "Yredelemnul",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 30,
    piety_mode = modes.ORDINARY,
    wrath_module = "policy.religion.wrath.yredelemnul",
    evil = true,
    conduct_module = "policy.religion.conduct.yredelemnul",
    behavior_module = "policy.religion.gods.yredelemnul",
    requires_love = true,
}

register.definition(categories.GODS, definition)

return definition

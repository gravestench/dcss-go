-- Okawaru uses the ordinary piety path; martial rewards are handled by later god systems.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.OKAWARU,
    name = "Okawaru",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 25,
    behavior_module = "policy.religion.gods.okawaru",
    piety_mode = modes.ORDINARY,
    conduct_module = "policy.religion.conduct.okawaru",
}

register.definition(categories.GODS, definition)

return definition

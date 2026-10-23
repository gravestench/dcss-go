-- Jiyva needs slime allies, so No Love prevents worship; gift timeout never slows gains.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.JIYVA,
    name = "Jiyva",
    temple_eligible = false,
    starting_piety = 15,
    wrath_penance = 30,
    piety_mode = modes.ORDINARY,
    conduct_module = "policy.religion.conduct.jiyva",
    requires_love = true,
    behavior_module = "policy.religion.gods.jiyva",
}

register.definition(categories.GODS, definition)

return definition

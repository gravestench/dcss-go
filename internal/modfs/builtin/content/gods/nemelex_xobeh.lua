-- Nemelex Xobeh uses ordinary piety, but its gift timeout is exempt from the usual slowdown.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.NEMELEX_XOBEH,
    name = "Nemelex Xobeh",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 50,
    piety_mode = modes.ORDINARY,
    piety_decay_chance = 35,
    conduct_module = "policy.religion.conduct.nemelex_xobeh",
}

register.definition(categories.GODS, definition)

return definition

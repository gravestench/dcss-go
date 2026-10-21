-- Xom uses its piety field as a mood around the midpoint, not as ordinary earned devotion.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.XOM,
    name = "Xom",
    temple_eligible = true,
    starting_piety = 100,
    wrath_penance = 50,
    piety_mode = modes.XOM,
    behavior_module = "policy.religion.gods.xom",
}

register.definition(categories.GODS, definition)

return definition

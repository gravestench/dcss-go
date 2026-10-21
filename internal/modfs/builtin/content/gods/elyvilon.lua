-- Elyvilon is good and later healing rules can raise piety; its gift timeout does not slow gains.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.ELYVILON,
    name = "Elyvilon",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 50,
    piety_mode = modes.ORDINARY,
    good = true,
}

register.definition(categories.GODS, definition)

return definition

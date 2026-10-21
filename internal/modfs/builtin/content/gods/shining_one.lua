-- The Shining One is good; a living, non-demonic worshipper may join unless Lich Form temporarily intervenes.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.SHINING_ONE,
    name = "the Shining One",
    temple_eligible = true,
    starting_piety = 15,
    piety_mode = modes.ORDINARY,
    good = true,
}

register.definition(categories.GODS, definition)

return definition

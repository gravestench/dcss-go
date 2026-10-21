-- Wu Jian begins with ordinary piety; martial movement rules belong to later systems.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.WU_JIAN,
    name = "Wu Jian",
    temple_eligible = true,
    starting_piety = 15,
    piety_mode = modes.ORDINARY,
}

register.definition(categories.GODS, definition)

return definition

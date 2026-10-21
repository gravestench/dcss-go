-- Ru starts at ten piety and tops out at the sixth-star threshold after sacrifices.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.RU,
    name = "Ru",
    temple_eligible = true,
    starting_piety = 10,
    piety_mode = modes.ORDINARY,
}

register.definition(categories.GODS, definition)

return definition

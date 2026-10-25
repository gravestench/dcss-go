-- This modded god proves a new content file can name its own wrath effect.
-- It is good, so its penance becomes active only against an evil patron.
local categories = require("constants.catalog")
local modes = require("constants.god_piety_modes")

local definition = {
    id = "GOD_TEST_WROUGHT",
    name = "Wrought",
    temple_eligible = false,
    starting_piety = 15,
    wrath_penance = 8,
    piety_mode = modes.ORDINARY,
    good = true,
    wrath_module = "policy.religion.wrath.test_wrought",
}

register.definition(categories.GODS, definition)

return definition

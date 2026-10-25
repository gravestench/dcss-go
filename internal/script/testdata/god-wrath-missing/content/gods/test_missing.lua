-- A misspelled wrath path must fail before a modded god can be worshipped.
-- This fixture contains only the winning definition, not an effect file.
local categories = require("constants.catalog")
local modes = require("constants.god_piety_modes")

local definition = {
    id = "GOD_TEST_MISSING_WRATH",
    name = "Missing Wrath",
    temple_eligible = false,
    starting_piety = 15,
    wrath_penance = 8,
    piety_mode = modes.ORDINARY,
    wrath_module = "policy.religion.wrath.not_present",
}

register.definition(categories.GODS, definition)

return definition

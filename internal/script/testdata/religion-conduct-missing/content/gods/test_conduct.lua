-- This sparse test god deliberately names a missing behavior file so boot
-- validation can report its winning content path before gameplay begins.
local categories = require("constants.catalog")
local modes = require("constants.god_piety_modes")

local definition = {
    id = "GOD_TEST_CONDUCT",
    name = "Test Conduct",
    temple_eligible = false,
    starting_piety = 15,
    wrath_penance = 20,
    piety_mode = modes.ORDINARY,
    conduct_module = "policy.religion.conduct.not_present",
}

register.definition(categories.GODS, definition)

return definition

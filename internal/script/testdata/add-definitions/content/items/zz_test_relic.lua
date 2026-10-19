-- A unique relic in a custom item class tests catalog loading without random generation.

local categories = require("constants.catalog")

local definition = {
    id = "UNRAND_TEST_RELIC",
    name = "test relic",
    class = "OBJ_TEST_RELICS",
    unique = true,
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

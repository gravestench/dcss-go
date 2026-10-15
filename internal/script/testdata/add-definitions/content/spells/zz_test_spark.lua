local categories = require("constants.catalog")

local definition = {
    id = "SPELL_TEST_SPARK",
    name = "Test Spark",
    status = "defined",
    level = 1,
}

register.definition(categories.SPELLS, definition)

return definition

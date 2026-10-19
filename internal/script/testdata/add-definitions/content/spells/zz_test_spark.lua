-- Test Spark supplies the spell id referenced by a modded item and resolver.

local categories = require("constants.catalog")
local scopes = require("constants.spell_scopes")

local definition = {
    id = "SPELL_TEST_SPARK",
    name = "Test Spark",
    status = "defined",
    level = 1,
    player_scope = scopes.BOOK,
}

register.definition(categories.SPELLS, definition)

return definition

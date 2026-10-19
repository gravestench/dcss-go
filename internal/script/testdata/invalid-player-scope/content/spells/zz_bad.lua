-- Bad Scope uses unsupported player scope metadata for spell validation.

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BAD_SCOPE",
    name = "Bad Scope",
    status = "defined",
    level = 1,
    player_scope = "everyone",
}

register.definition(categories.SPELLS, definition)

return definition

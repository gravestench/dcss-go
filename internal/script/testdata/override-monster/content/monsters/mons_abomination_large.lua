-- The Abomination id keeps its key while replacing the display name.

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ABOMINATION_LARGE",
    name = "renamed abomination",
    vault_aliases = { "large abomination" },
    status = "defined",
    habitat_id = "HT_LAND",
    spellbook_id = "MST_NO_SPELLS",
}

register.definition(categories.MONSTERS, definition)

return definition

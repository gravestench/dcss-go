local categories = require("constants.catalog")

local definition = {
    id = "MONS_ABOMINATION_LARGE",
    name = "renamed abomination",
    status = "defined",
    habitat_id = "HT_LAND",
    spellbook_id = "MST_NO_SPELLS",
}

register.definition(categories.MONSTERS, definition)

return definition

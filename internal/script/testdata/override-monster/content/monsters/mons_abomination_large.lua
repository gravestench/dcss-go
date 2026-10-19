-- The Abomination id keeps its key while replacing the display name.

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ABOMINATION_LARGE",
    name = "renamed abomination",
    vault_aliases = { "large abomination" },
    status = "defined",
    habitat_id = "HT_LAND",
    spellbook_id = spellbooks.MST_NO_SPELLS,
}

register.definition(categories.MONSTERS, definition)

return definition

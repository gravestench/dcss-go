-- A second Abomination definition tests duplicate id rejection within one layer.

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ABOMINATION_LARGE",
    name = "duplicate abomination",
}

register.definition(categories.MONSTERS, definition)

return definition

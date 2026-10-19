local categories = require("constants.catalog")

-- SP_INCOMPLETE deliberately omits species fields so catalog validation
-- reports this definition's origin and ID.
local definition = {
    id = "SP_INCOMPLETE",
    name = "Incomplete",
}

register.definition(categories.SPECIES, definition)

return definition

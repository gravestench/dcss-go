local categories = require("constants.catalog")

-- Duplicate registrations must fail before startup completes.
local definition = {
    id = "SP_HUMAN",
}

register.definition(categories.SPECIES, definition)

return definition

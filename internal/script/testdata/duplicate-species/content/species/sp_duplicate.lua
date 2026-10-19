local categories = require("constants.catalog")

-- Re-registering bundled SP_HUMAN from a separate file must fail during
-- catalog load before any species choice can run.
local definition = {
    id = "SP_HUMAN",
}

register.definition(categories.SPECIES, definition)

return definition

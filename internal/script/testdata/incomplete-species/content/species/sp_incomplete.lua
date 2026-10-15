local categories = require("constants.catalog")

-- Test fixture: incomplete Lua definitions report their own path and ID.
local definition = {
    id = "SP_INCOMPLETE",
    name = "Incomplete",
}

register.definition(categories.SPECIES, definition)

return definition

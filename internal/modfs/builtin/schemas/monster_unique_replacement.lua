-- A later Boris is neither an ambient roster draw nor an authored vault
-- actor. This saved marker explains his source replacement path to restore.
local component = require("constants.component")

local schema = {
    id = component.UNIQUE_REPLACEMENT,
    version = 1,
    fields = {
        kind_id = {
            type = "string",
        },
    },
}

register.component(schema)

return schema

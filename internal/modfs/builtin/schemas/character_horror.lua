local component = require("constants.component")

local schema = {
    id = component.HORROR,
    version = 1,
    -- The current Cowardice penalty is cached on the player for spell power and status consumers.
    fields = {
        penalty = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

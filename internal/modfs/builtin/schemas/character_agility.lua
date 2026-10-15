local component = require("constants.component")

-- Source: DUR_AGILITY is persistent player duration state.
local schema = {
    id = component.AGILITY,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

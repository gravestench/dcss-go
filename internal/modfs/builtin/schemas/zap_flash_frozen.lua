local component = require("constants.component")

local schema = {
    id = component.FLASH_FROZEN,
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

local component = require("constants.component")

local schema = {
    id = component.FLASH_FROZEN,
    version = 1,
    -- The freeze timer remains on the struck actor after the flash resolves.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

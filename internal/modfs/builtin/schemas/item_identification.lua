local component = require("constants.component")

local schema = {
    id = component.ITEM_IDENTIFICATION,
    version = 1,
    fields = {
        known_type = {
            type = "bool",
            default = false,
        },

        known_pluses = {
            type = "bool",
            default = false,
        },

        known_properties = {
            type = "bool",
            default = false,
        },

        cosmetic = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

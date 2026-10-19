local component = require("constants.component")

local schema = {
    id = component.ITEM_IDENTIFICATION,
    version = 1,
    -- Type, plus, and property discovery are separate, so revealing one does not identify the others.
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

local component = require("constants.component")

local schema = {
    id = component.SEEN_BY_PLAYER,
    version = 1,
    fields = {
        visible = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

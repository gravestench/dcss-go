local component = require("constants.component")

local schema = {
    id = component.HORROR,
    version = 1,
    fields = {
        penalty = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

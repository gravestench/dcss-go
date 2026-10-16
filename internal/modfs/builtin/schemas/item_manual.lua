local component = require("constants.component")

local schema = {
    id = component.ITEM_MANUAL,
    version = 1,
    fields = {
        skill_id = {
            type = "string",
            default = "",
        },
        points = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

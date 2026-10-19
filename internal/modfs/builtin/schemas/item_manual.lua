local component = require("constants.component")

local schema = {
    id = component.ITEM_MANUAL,
    version = 1,
    -- A manual retains its target skill and unread training points as item state.
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

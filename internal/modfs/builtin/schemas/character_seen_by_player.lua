local component = require("constants.component")

local schema = {
    id = component.SEEN_BY_PLAYER,
    version = 1,
    -- Visibility on an individual actor survives its last perception update for message and reveal decisions.
    fields = {
        visible = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

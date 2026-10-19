local component = require("constants.component")

local schema = {
    id = component.PLAYER_UNIQUE_HISTORY,
    version = 1,
    -- Unique generation state persists separately from living actors so a killed unique is not selected again.
    fields = {
        status = {
            type = "map<string,string>",
        },
    },
}

register.component(schema)

return schema

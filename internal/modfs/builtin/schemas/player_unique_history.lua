local component = require("constants.component")

local schema = {
    id = component.PLAYER_UNIQUE_HISTORY,
    version = 1,
    fields = {
        status = {
            type = "map<string,string>",
        },
    },
}

register.component(schema)

return schema

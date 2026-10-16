local component = require("constants.component")

local schema = {
    id = component.PLAYER_ITEM_SETS,
    version = 1,
    fields = {
        choices = {
            type = "map<string,string>",
        },
    },
}

register.component(schema)

return schema

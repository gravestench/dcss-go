local component = require("constants.component")

local schema = {
    id = component.PLAYER_ITEM_SETS,
    version = 1,
    -- The selected item set for each key survives between inventory interactions.
    fields = {
        choices = {
            type = "map<string,string>",
        },
    },
}

register.component(schema)

return schema

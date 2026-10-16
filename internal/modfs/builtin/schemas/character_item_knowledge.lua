local component = require("constants.component")

local schema = {
    id = component.ITEM_KNOWLEDGE,
    version = 2,
    fields = {
        known_types = {
            type = "map<string,bool>",
        },

        seen_types = {
            type = "map<string,bool>",
        },

        appearance_seeds = {
            type = "map<string,int64>",
        },
    },
}

register.component(schema)

return schema

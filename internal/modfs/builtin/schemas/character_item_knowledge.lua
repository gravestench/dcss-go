local component = require("constants.component")

local schema = {
    id = component.ITEM_KNOWLEDGE,
    version = 2,
    -- Known and seen item types stay separate; appearance seeds keep unidentified looks stable across saves.
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

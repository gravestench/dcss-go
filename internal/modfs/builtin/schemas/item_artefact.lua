local component = require("constants.component")

local schema = {
    id = component.ITEM_ARTEFACT,
    version = 1,
    -- Seed and unique ID reproduce generated identity; knowledge flags are separate from actual properties.
    fields = {
        kind = {
            type = "string",
            default = "",
        },
        unique_id = {
            type = "string",
            default = "",
        },
        seed = {
            type = "uint64",
            default = 0,
        },
        name = {
            type = "string",
            default = "",
        },
        appearance = {
            type = "string",
            default = "",
        },
        brand = {
            type = "string",
            default = "",
        },
        properties = {
            type = "map<string,int64>",
        },
        known = {
            type = "map<string,bool>",
        },
        flags = {
            type = "list<string>",
        },
    },
}

register.component(schema)

return schema

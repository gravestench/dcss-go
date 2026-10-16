local component = require("constants.component")

local schema = {
    id = component.ITEM_RANDOM_BOOK,
    version = 1,
    fields = {
        spells = {
            type = "list<string>",
        },
        theme = {
            type = "string",
            default = "",
        },
        level = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

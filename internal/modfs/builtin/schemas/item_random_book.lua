local component = require("constants.component")

local schema = {
    id = component.ITEM_RANDOM_BOOK,
    version = 1,
    -- The chosen spell list, theme, and level are fixed when the book is generated.
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

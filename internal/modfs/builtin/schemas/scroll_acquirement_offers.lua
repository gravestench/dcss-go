-- An acquirement scroll keeps its generated choices across save and cancel.
local component = require("constants.component")

local schema = {
    id = component.SCROLL_ACQUIREMENT,
    version = 1,
    fields = {
        kind_ids = {
            type = "list<string>",
        },
        pluses = {
            type = "list<int64>",
        },
        quantities = {
            type = "list<int64>",
        },
    },
}

register.component(schema)

return schema

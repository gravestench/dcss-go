-- A periodic jelly was created during play, outside any starting roster or
-- authored vault. Its saved origin lets restore validate that exception.
local component = require("constants.component")

local schema = {
    id = component.JIYVA_SPAWN,
    version = 1,
    fields = {
        created_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

local component = require("constants.component")

local schema = {
    id = component.MONSTER_MUTE,
    version = 1,
    -- The monster keeps its silence timer after the zap beam leaves its cell.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

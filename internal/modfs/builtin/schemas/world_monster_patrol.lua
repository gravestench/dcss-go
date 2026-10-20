-- The patrol point belongs to one live monster even after that monster
-- leaves its vault cell. AI can forget a foe and return to this anchor.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_PATROL,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        x = {
            type = "int64",
            default = 0,
        },
        y = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

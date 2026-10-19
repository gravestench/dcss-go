-- A vine's victim owns the grip link and its escape progress. Keeping the
-- source entity in ECS lets movement, dragging, death, and saves agree.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_VINE_GRIP,
    version = 1,
    fields = {
        by = {
            type = "entity",
        },
        escape_attempts = {
            type = "int64",
            default = 0,
        },
        held_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

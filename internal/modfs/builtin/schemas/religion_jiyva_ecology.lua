-- The source runs Jiyva's timer at random 100–300 aut intervals. Persist
-- the next firing so reloading cannot reroll or repeat a pending event.
local component = require("constants.component")

local schema = {
    id = component.JIYVA_ECOLOGY,
    version = 1,
    fields = {
        next_due_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

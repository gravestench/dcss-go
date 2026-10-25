-- A submerged monster is hidden under its current terrain. The marker lets
-- attack reactions check that live state without adding species exceptions.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_SUBMERGED,
    version = 1,
    fields = {
        active = {
            type = "bool",
            default = true,
        },
    },
}

register.component(schema)

return schema

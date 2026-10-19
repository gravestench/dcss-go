-- A live spore remembers its chosen foe and whether its one explosion has
-- fired. This stops death and timeout phases from detonating it twice.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_SPORE,
    version = 1,
    fields = {
        target = {
            type = "entity",
        },
        exploded = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

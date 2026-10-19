local component = require("constants.component")

-- The aura can expire before its absolute recast clock. Saving both fields
-- prevents a reload or level change from granting an early second cast.
local schema = {
    id = component.MONSTER_INJURY_MIRROR,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },

        recast_at_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

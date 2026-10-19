local component = require("constants.component")

-- Trog's Hand grants regeneration and strong will for one shared source
-- duration. One saved timer prevents the two protections drifting apart.
local schema = {
    id = component.MONSTER_TROGS_HAND,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

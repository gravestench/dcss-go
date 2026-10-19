-- The dryad owns one timer for all vines it animates. Each vine separately
-- records its tree anchor, so a save can restore the full relationship.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_AWAKE_VINES,
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

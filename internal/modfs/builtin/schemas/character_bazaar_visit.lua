-- The active visitor remembers the exact outside gate. The chosen map
-- belongs to its level record; this link only exists during the visit.
local component = require("constants.component")

register.component({
    id = component.PLAYER_BAZAAR_VISIT,
    version = 1,
    fields = {
        origin_level_id = {
            type = "int64",
            default = 0,
        },
        origin_x = {
            type = "int64",
            default = 0,
        },
        origin_y = {
            type = "int64",
            default = 0,
        },
        level_id = {
            type = "int64",
            default = 0,
        },
        vault_id = {
            type = "string",
            default = "",
        },
    },
})

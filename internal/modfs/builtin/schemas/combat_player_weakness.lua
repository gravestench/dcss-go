-- Source player::weaken stores a bounded duration on the player. Keeping
-- it as an ECS component makes the melee penalty and save resume agree.
local component = require("constants.component")

local schema = {
    id = component.PLAYER_WEAKNESS,
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

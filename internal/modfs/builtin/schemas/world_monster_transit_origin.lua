-- Ordinary monsters retain their spawn roster when they follow the player
-- across branches. The first source branch survives later travel, including
-- replacement of a Pandemonium region that no longer has a saved level.
local component = require("constants.component")

register.component({
    id = component.MONSTER_TRANSIT_ORIGIN,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        branch_id = {
            type = "string",
            default = "",
        },
    },
})

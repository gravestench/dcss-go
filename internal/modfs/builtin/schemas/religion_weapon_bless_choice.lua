-- A free god capstone menu may cross save/restore before confirmation.
-- The selected entity and exact ability bind that future timed action.
local component = require("constants.component")

register.component({
    id = component.WEAPON_BLESS_CHOICE,
    version = 1,
    fields = {
        item = {
            type = "entity",
        },
        ability_id = {
            type = "string",
            default = "",
        },
        god_id = {
            type = "string",
            default = "",
        },
    },
})

-- Source breath recovery persists with the individual monster. An
-- remaining own actions preserve recovery for fast and slow monsters.
local component = require("constants.component")

register.component({
    id = component.MONSTER_BREATH_COOLDOWN,
    version = 1,
    fields = {
        remaining_actions = {
            type = "int64",
            default = 0,
        },
    },
})

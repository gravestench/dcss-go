-- Protection weapon hits create a short player-owned aura. It is saved as
-- an ECS component so equipping another weapon cannot reset its clock.
local component = require("constants.component")

register.component({
    id = component.WEAPON_PROTECTION,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
})

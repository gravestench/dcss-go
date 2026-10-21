-- A particular hydra's head count belongs to the actor, not its species.
-- Authored baby hydras and undead hydras keep that count across saves.
local component = require("constants.component")

register.component({
    id = component.MONSTER_HYDRA_HEADS,
    version = 1,
    fields = {
        count = {
            type = "int64",
            default = 0,
        },
    },
})

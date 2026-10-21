-- A delayed vault callback can create a permanent actor after population.
-- The source marker remains on the level; this component joins that marker
-- to the saved actor so restore does not mistake it for a random monster.
local component = require("constants.component")

register.component({
    id = component.WORLD_VAULT_SPAWN,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        vault_id = {
            type = "string",
            default = "",
        },
        trigger_index = {
            type = "int64",
            default = 0,
        },
        target_x = {
            type = "int64",
            default = 0,
        },
        target_y = {
            type = "int64",
            default = 0,
        },
    },
})

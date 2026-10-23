-- Borgnjor's death listener has no timer, but it still needs a saved
-- source marker witness so unrelated monster deaths cannot activate it.
local component = require("constants.component")

register.component({
    id = component.WORLD_WIZLAB_BORGNJOR,
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
        marker_index = {
            type = "int64",
            default = 0,
        },
    },
})

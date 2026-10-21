-- The overgrown Zot stairs keep their countdown and each plant target in
-- saved ECS state. The source DES remains the owner of target coordinates.
local component = require("constants.component")

register.component({
    id = component.WORLD_ZOT_OVERGROWN,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        x = {
            type = "int64",
            default = 0,
        },
        y = {
            type = "int64",
            default = 0,
        },
        vault_id = {
            type = "string",
            default = "",
        },
        role = {
            type = "string",
            default = "",
        },
        started = {
            type = "bool",
            default = false,
        },
        next_aut = {
            type = "int64",
            default = 0,
        },
        count = {
            type = "int64",
            default = 0,
        },
        warned = {
            type = "bool",
            default = false,
        },
    },
})

-- Summoned monks and lost souls need durable callback provenance. The
-- ordinary vault-origin component is reserved for initial DES monsters
-- and would falsely claim that these later actors came from KMONS.
local component = require("constants.component")

register.component({
    id = component.WORLD_WIZLAB_EVENT_ACTOR,
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
        source_index = {
            type = "int64",
            default = 0,
        },
        kind = {
            type = "string",
            default = "",
        },
    },
})

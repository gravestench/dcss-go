-- One generated entity links to one authored placement record.
local component = require("constants.component")

local schema = {
    id = component.VAULT_ORIGIN,
    version = 1,
    -- Vault ID and record index identify the authored placement; occurrence distinguishes repeated spawns.
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },

        vault_id = {
            type = "string",
            default = "",
        },

        kind_id = {
            type = "string",
            default = "",
        },

        record_index = {
            type = "int64",
            default = 0,
        },

        occurrence = {
            type = "int64",
            default = 0,
        },

        spawn_x = {
            type = "int64",
            default = 0,
        },

        spawn_y = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

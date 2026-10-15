-- Player summons keep their origin and timeout through save and restore.
local categories = require("constants.catalog")

local schema = {
    id = "magic.summon",
    version = 3,
    fields = {
        owner = {
            type = "entity",
        },

        source_category = {
            type = "string",
            default = categories.SPELLS,
        },

        source_id = {
            type = "string",
            default = "",
        },

        expires_aut = {
            type = "int64",
            default = 0,
        },

        heads = {
            type = "int64",
            default = 0,
        },

        hostile = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

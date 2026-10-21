-- A mutable ugly thing saves its individual appearance, melee attack, and
-- defenses. The catalog supplies only the immutable species baseline.
local component = require("constants.component")

local schema = {
    id = component.UGLY_THING,
    version = 1,
    fields = {
        colour_id = {
            type = "string",
            default = "",
        },

        adjective = {
            type = "string",
            default = "",
        },

        attack_type_id = {
            type = "string",
            default = "",
        },

        flavour_id = {
            type = "string",
            default = "",
        },

        damage = {
            type = "int64",
            default = 0,
        },

        resistances = {
            type = "map<string,int64>",
            default = {},
        },
    },
}

register.component(schema)

return schema

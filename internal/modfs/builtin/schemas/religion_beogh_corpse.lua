-- An orc corpse saves its identity and dropped gear independently of the
-- actor entity destroyed by the ordinary death phase. Resurrection reads
-- this record after a save instead of rerolling the old monster.
local component = require("constants.component")

local schema = {
    id = component.BEOGH_CORPSE,
    version = 1,
    fields = {
        kind_id = {
            type = "string",
            default = "",
        },

        max_hp = {
            type = "int64",
            default = 0,
        },

        speed = {
            type = "int64",
            default = 0,
        },

        hit_dice = {
            type = "int64",
            default = 0,
        },

        custom_name = {
            type = "string",
            default = "",
        },

        name_adjective = {
            type = "bool",
            default = false,
        },

        gift_category = {
            type = "string",
            default = "",
        },

        dropped_gear = {
            type = "map<string,int64>",
            default = {},
        },
    },
}

register.component(schema)

return schema

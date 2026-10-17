-- The portal marker persists through the tentacle's occupation of its cell.
local categories = require("constants.catalog")
local spells = require("ids.spells")

local schema = {
    id = "magic.summon_gateway",
    version = 1,
    fields = {
        owner = { type = "entity" },
        level_id = { type = "int64", default = 0 },
        x = { type = "int64", default = 0 },
        y = { type = "int64", default = 0 },
        original_feature = { type = "string", default = "" },
        expires_aut = { type = "int64", default = 0 },
        power = { type = "int64", default = 0 },
        phase = { type = "int64", default = 0 },
        tentacle_id = { type = "int64", default = 0 },
        source_category = {
            type = "string",
            default = categories.SPELLS,
        },

        source_id = {
            type = "string",
            default = spells.SPELL_MALIGN_GATEWAY,
        },

        hostile = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

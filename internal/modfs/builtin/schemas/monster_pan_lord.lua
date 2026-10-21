-- A random Pan lord rolls its own body and spells once. The actor owns that
-- result so save/restore cannot quietly generate a different opponent.
local component = require("constants.component")

local schema = {
    id = component.PANDEMONIUM_LORD,
    version = 1,
    fields = {
        hp = {
            type = "int64",
            default = 0,
        },

        speed = {
            type = "int64",
            default = 0,
        },

        spellcaster = {
            type = "bool",
            default = false,
        },

        hd = {
            type = "int64",
            default = 0,
        },

        ac = {
            type = "int64",
            default = 0,
        },

        ev = {
            type = "int64",
            default = 0,
        },

        damage = {
            type = "int64",
            default = 0,
        },

        flies = {
            type = "bool",
            default = false,
        },

        resistances = {
            type = "map<string,int64>",
            default = {},
        },

        attack_type_id = {
            type = "string",
            default = "",
        },

        flavour_id = {
            type = "string",
            default = "",
        },

        brand_id = {
            type = "string",
            default = "",
        },

        -- One persistent source ring choice drives live cloud placement.
        -- Saving it prevents restore from drawing a different cloud type.
        ring_id = {
            type = "string",
            default = "",
        },

        spell_ids = {
            type = "list<string>",
            default = {},
        },

        frequencies = {
            type = "list<int64>",
            default = {},
        },
    },
}

register.component(schema)

return schema

-- Mara's illusion copies a player-ghost profile once. Every field belongs to
-- this actor, so a later equipment change cannot alter the existing copy.
local component = require("constants.component")

local schema = {
    id = component.PLAYER_ILLUSION,
    version = 2,
    fields = {
        name = {
            type = "string",
            default = "",
        },

        species_id = {
            type = "string",
            default = "",
        },

        job_id = {
            type = "string",
            default = "",
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

        necromancy_skill = {
            type = "int64",
            default = 0,
        },

        brand_id = {
            type = "string",
            default = "",
        },

        holiness_id = {
            type = "string",
            default = "",
        },

        see_invisible = {
            type = "bool",
            default = false,
        },

        resistances = {
            type = "map<string,int64>",
            default = {},
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

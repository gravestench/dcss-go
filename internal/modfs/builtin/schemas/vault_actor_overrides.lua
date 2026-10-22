local component = require("constants.component")

local schema = {
    id = component.VAULT_ACTOR_OVERRIDES,
    version = 5,
    -- Authored variant, colour, attitude, and spell overrides travel with the spawned vault actor.
    fields = {
        base_id = {
            type = "string",
            default = "",
        },

        variant = {
            type = "string",
            default = "",
        },

        colour = {
            type = "string",
            default = "",
        },

        attitude = {
            type = "string",
            default = "hostile",
        },

        -- Source god: annotations belong to an individual authored actor.
        god_id = {
            type = "string",
            default = "",
        },

        spells = {
            type = "list<string>",
            default = {},
        },

        -- A DES hp:/hd: pair overrides the ordinary roster roll and the
        -- source species' combat strength for this actor only.
        fixed_hp = {
            type = "int64",
            default = 0,
        },

        hit_dice = {
            type = "int64",
            default = 0,
        },

        -- Source naming is per entity. An adjective combines with the
        -- species, while a plain custom name replaces it in messages.
        custom_name = {
            type = "string",
            default = "",
        },

        name_adjective = {
            type = "bool",
            default = false,
        },

        -- DES name_species preserves the corpse's authored species label;
        -- it is independent of adjective grammar on the living monster.
        name_species = {
            type = "bool",
            default = false,
        },

        -- DES dbname: is an internal identity hint; tile: is kept for a
        -- graphical client without affecting the terminal glyph.
        database_name = {
            type = "string",
            default = "",
        },

        tile = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema

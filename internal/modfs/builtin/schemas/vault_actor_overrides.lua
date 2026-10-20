local component = require("constants.component")

local schema = {
    id = component.VAULT_ACTOR_OVERRIDES,
    version = 2,
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
    },
}

register.component(schema)

return schema

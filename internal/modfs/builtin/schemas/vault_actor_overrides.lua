local component = require("constants.component")

local schema = {
    id = component.VAULT_ACTOR_OVERRIDES,
    version = 1,
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

        spells = {
            type = "list<string>",
            default = {},
        },
    },
}

register.component(schema)

return schema

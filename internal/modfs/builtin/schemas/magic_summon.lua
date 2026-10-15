-- Player summons keep their origin and timeout through save and restore.
local schema = {
    id = "magic.summon",
    version = 1,
    fields = {
        owner = {
            type = "entity",
        },

        spell_id = {
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
    },
}

register.component(schema)

return schema

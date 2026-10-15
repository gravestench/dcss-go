-- Source: ENCH_SIMULACRUM marks a living monster until death or timeout.
local schema = {
    id = "magic.summon_mark",
    version = 1,
    fields = {
        owner = {
            type = "entity",
        },

        expires_aut = {
            type = "int64",
            default = 0,
        },

        power = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

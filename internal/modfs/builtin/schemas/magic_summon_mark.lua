-- Source: ENCH_SIMULACRUM marks a living monster until death or timeout.
local schema = {
    id = "magic.summon_mark",
    version = 1,
    -- The marked victim retains caster, expiry, and power until death can create a simulacrum.
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

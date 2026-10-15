-- Delayed, MP-funded Dragon Call continues through save and restore.
local schema = {
    id = "magic.summon_dragon_call",
    version = 1,
    fields = {
        ends_aut = {
            type = "int64",
            default = 0,
        },

        next_aut = {
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

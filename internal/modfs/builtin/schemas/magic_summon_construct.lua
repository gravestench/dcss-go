-- Source conjurations retain their power and action count across save/restore.
local schema = {
    id = "magic.summon_construct",
    version = 1,
    -- Construct power and charge determine future attacks without rerolling its original cast.
    fields = {
        power = {
            type = "int64",
            default = 0,
        },
        charge = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

-- Per-cast hit dice overrides from source summoning functions.
local schema = {
    id = "magic.summon_stats",
    version = 1,
    fields = {
        hd = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

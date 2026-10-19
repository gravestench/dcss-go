-- Per-cast hit dice overrides from source summoning functions.
local schema = {
    id = "magic.summon_stats",
    version = 1,
    -- The rolled hit-dice override remains attached to the summoned actor for derived stats.
    fields = {
        hd = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

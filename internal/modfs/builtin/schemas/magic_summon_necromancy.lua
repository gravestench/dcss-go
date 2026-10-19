-- Cast auras persist across saves and are consumed when a qualifying actor dies.
local schema = {
    id = "magic.summon_necromancy",
    version = 1,
    -- Death Channel and Animate Dead keep separate aura expiries; animate power belongs to the cast.
    fields = {
        death_channel_expires_aut = { type = "int64", default = 0 },
        animate_dead_expires_aut = { type = "int64", default = 0 },
        animate_power = { type = "int64", default = 0 },
    },
}

register.component(schema)

return schema

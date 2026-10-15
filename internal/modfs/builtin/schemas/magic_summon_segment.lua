-- A gateway tentacle's connector actors persist with their head and portal.
local schema = {
    id = "magic.summon_segment",
    version = 1,
    fields = {
        head = { type = "entity" },
        gateway = { type = "entity" },
        index = { type = "int64", default = 0 },
    },
}

register.component(schema)

return schema

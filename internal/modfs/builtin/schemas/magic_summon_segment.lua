-- A gateway tentacle's connector actors persist with their head and portal.
local schema = {
    id = "magic.summon_segment",
    version = 1,
    -- Each tentacle connector links to its head and gateway, with index preserving segment order.
    fields = {
        head = { type = "entity" },
        gateway = { type = "entity" },
        index = { type = "int64", default = 0 },
    },
}

register.component(schema)

return schema

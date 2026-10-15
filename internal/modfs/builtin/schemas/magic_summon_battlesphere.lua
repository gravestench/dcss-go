-- Charge and source power for a conjuration-mirroring battlesphere.
local schema = {
    id = "magic.summon_battlesphere",
    version = 1,
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

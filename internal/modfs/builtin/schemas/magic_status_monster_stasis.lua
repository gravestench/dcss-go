-- Source: actor.cc sleep rules; beam.cc Petrify's two-stage enchantment.
local schema = {
    id = "magic.monster_stasis",
    version = 1,
    -- Sleep wariness and the two petrification phases continue independently of hibernation.
    fields = {
        hibernating = {
            type = "bool",
            default = false,
        },

        sleep_wary_aut = {
            type = "int64",
            default = 0,
        },

        petrifying_aut = {
            type = "int64",
            default = 0,
        },

        petrified_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

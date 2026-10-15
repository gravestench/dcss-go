-- Source: beam.cc:mass_enchantment; saved monster enchant durations.
local schema = {
    id = "magic.monster_mass_enchant",
    version = 1,
    fields = {
        fear_aut = {
            type = "int64",
            default = 0,
        },

        anguish_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

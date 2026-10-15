-- Chaos weapon enchantments belong to the affected monster and survive saves.
local schema = {
    id = "combat.monster_chaos",
    version = 1,
    fields = {
        haste_aut = {
            type = "int64",
            default = 0,
        },

        might_aut = {
            type = "int64",
            default = 0,
        },

        agility_aut = {
            type = "int64",
            default = 0,
        },

        shifter = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

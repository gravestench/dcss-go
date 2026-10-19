-- Chaos weapon enchantments belong to the affected monster and survive saves.
local schema = {
    id = "combat.monster_chaos",
    version = 1,
    -- Chaos haste, might, and agility timers belong to the affected monster; shifter marks its lasting variant.
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

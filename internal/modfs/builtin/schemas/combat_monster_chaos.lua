-- Chaos weapon enchantments belong to the affected monster and survive saves.
local schema = {
    id = "combat.monster_chaos",
    version = 2,
    -- Agility and shifter identity are Chaos-specific. Generic Haste and
    -- Might live in combat.monster_boons so spells share the same owner.
    fields = {
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

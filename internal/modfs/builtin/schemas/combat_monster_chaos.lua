-- Chaos weapon enchantments belong to the affected monster and survive saves.
local schema = {
    id = "combat.monster_chaos",
    version = 3,
    -- Only timed agility remains here. Natural and Chaos-created shifters
    -- share combat.monster_shapeshifter as their permanent state owner.
    fields = {
        agility_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

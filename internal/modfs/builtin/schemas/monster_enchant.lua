-- Magical monster conditions are owned by the affected ECS actor.
register.component{
    id = "magic.monster_enchant",
    version = 2,
    -- Blindness, corrosion, and invisibility timers are owned by the affected monster and expire separately.
    fields = {
        blind_aut = {
            type = "int64",
            default = 0,
        },

        corrosion_aut = {
            type = "int64",
            default = 0,
        },

        invisible_aut = {
            type = "int64",
            default = 0,
        },
    },
}

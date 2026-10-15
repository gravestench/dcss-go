-- Magical monster conditions are owned by the affected ECS actor.
register.component{
    id = "magic.monster_enchant",
    version = 1,
    fields = {
        blind_aut = {
            type = "int64",
            default = 0,
        },

        corrosion_aut = {
            type = "int64",
            default = 0,
        },
    },
}

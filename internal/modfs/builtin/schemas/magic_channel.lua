-- A channeled spell continues only while the player explicitly waits.
register.component{
    id = "magic.channel",
    version = 1,
    -- Power and target are fixed at cast start while stage records progress through explicit wait actions.
    fields = {
        spell_id = {
            type = "string",
            default = "",
        },

        power = {
            type = "int64",
            default = 0,
        },

        stage = {
            type = "int64",
            default = 0,
        },

        aimed_at_spot = {
            type = "bool",
            default = false,
        },

        target_x = {
            type = "int64",
            default = 0,
        },

        target_y = {
            type = "int64",
            default = 0,
        },

        target_monster = {
            type = "entity",
        },
    },
}

-- Durable source-derived facts from character creation. Later Lua systems
-- can read them without reconstructing randomized choices from the job ID.
register.component{
    id = "character.origin",
    version = 1,
    fields = {
        initial_skills = {
            type = "string",
            default = "",
        },

        strength_bonus = {
            type = "int64",
            default = 0,
        },

        intelligence_bonus = {
            type = "int64",
            default = 0,
        },

        dexterity_bonus = {
            type = "int64",
            default = 0,
        },

        innate_mutations = {
            type = "string",
            default = "",
        },

        religion = {
            type = "string",
            default = "GOD_NO_GOD",
        },

        piety = {
            type = "int64",
            default = 0,
        },

        gift_timeout = {
            type = "int64",
            default = 0,
        },
    },
}

-- Durable source-derived facts from character creation. Later Lua systems
-- can read them without reconstructing randomized choices from the job ID.
local component = require("constants.component")

register.component{
    id = component.CHARACTER_ORIGIN,
    version = 1,
    -- Creation bonuses and initial skills remain available after the randomized starting profile is discarded.
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

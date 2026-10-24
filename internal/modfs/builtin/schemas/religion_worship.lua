-- The player owns one durable record for current worship and per-god history.
-- Keep it separate from character origin: worship can change at an altar,
-- while the choices and bonuses made at character creation cannot.
local component = require("constants.component")
local gods = require("constants.gods")

local schema = {
    id = component.RELIGION_WORSHIP,
    version = 4,
    fields = {
        god_id = {
            type = "string",
            default = gods.NO_GOD,
        },

        piety = {
            type = "int64",
            default = 0,
        },

        piety_hysteresis = {
            type = "int64",
            default = 0,
        },

        gift_timeout = {
            type = "int64",
            default = 0,
        },

        -- Lifetime counts decide which spell set or offer window comes next.
        -- Current counts reset on departure, but lifetime history does not.
        gift_current = {
            type = "map<string,int64>",
        },

        gift_total = {
            type = "map<string,int64>",
        },

        -- God time starts at 200 aut and then rolls a 100–300 aut interval.
        -- Zero lets an older save initialize its own next deadline once.
        next_god_time_aut = {
            type = "int64",
            default = 0,
        },

        -- A missing god key means zero. Maps avoid adding a schema field each
        -- time a mod contributes another god definition.
        penance = {
            type = "map<string,int64>",
        },

        worshipped = {
            type = "map<string,int64>",
        },

        piety_max = {
            type = "map<string,int64>",
        },

        -- A capstone remains spent after changing gods or losing piety.
        -- Keys are god IDs so added gods need no new schema field.
        one_time_abilities = {
            type = "map<string,bool>",
        },

        previous_good_god = {
            type = "string",
            default = gods.NO_GOD,
        },

        saved_good_piety = {
            type = "int64",
            default = 0,
        },

        -- Ignis cannot regain spent starting piety by leaving and rejoining.
        min_ignis_piety = {
            type = "int64",
            default = 0,
        },

        -- Source Jiyva vanishes only after the Royal Jelly dies and
        -- the player's remaining penance is paid off.
        royal_jelly_dead = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

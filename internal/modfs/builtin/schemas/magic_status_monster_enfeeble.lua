-- Source: spl-monench.cc:enfeeble_monster and mon-ench.cc status durations.
local schema = {
    id = "magic.monster_enfeeble",
    version = 1,
    -- Weakness, antimagic, blindness, and daze expire separately after an enfeebling cast.
    fields = {
        weak_aut = {
            type = "int64",
            default = 0,
        },

        antimagic_aut = {
            type = "int64",
            default = 0,
        },

        blind_aut = {
            type = "int64",
            default = 0,
        },

        dazed_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

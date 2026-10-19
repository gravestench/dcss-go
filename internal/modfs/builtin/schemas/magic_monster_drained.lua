-- Source: monster.cc:monster::drain and mon-act.cc:get_hit_dice.
local schema = {
    id = "magic.monster_drained",
    version = 1,
    -- Drain degree changes effective hit dice while duration controls when the monster recovers.
    fields = {
        degree = {
            type = "int64",
            default = 0,
        },
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

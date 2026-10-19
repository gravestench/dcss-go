-- Source: beam.cc:BEAM_VILE_CLUTCH and actor.cc constriction state.
local schema = {
    id = "magic.monster_vile_clutch",
    version = 1,
    -- Clutch power, held time, and escape attempts stay on the grabbed monster until release.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },

        power = {
            type = "int64",
            default = 0,
        },

        held_aut = {
            type = "int64",
            default = 0,
        },

        escape_attempts = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

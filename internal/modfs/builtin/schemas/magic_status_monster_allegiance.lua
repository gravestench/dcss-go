-- Source: beam.cc:BEAM_CHARM and mass_enchantment(ENCH_INSANE).
local schema = {
    id = "magic.monster_allegiance",
    version = 1,
    -- Charm, frenzy, and fatigue durations coexist because changing attitude does not clear recovery.
    fields = {
        charm_aut = {
            type = "int64",
            default = 0,
        },

        frenzy_aut = {
            type = "int64",
            default = 0,
        },

        fatigue_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

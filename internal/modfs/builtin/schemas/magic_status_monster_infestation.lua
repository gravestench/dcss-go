-- Source: beam.cc:BEAM_INFESTATION and mon-ench.cc:ENCH_INFESTATION.
local schema = {
    id = "magic.monster_infestation",
    version = 1,
    -- The infestation mark remains on its victim until expiry or death-driven spawn resolution.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

-- Source: beam.cc:BEAM_CONFUSION and mon-ench.cc:ENCH_CONFUSION.
local schema = {
    id = "magic.monster_confusion",
    version = 1,
    -- The affected monster owns confusion duration for its own movement and action decisions.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

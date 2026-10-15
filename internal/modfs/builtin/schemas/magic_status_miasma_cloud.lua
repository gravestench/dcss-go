-- Source: mon-death.cc:_corpse_rot creates short lived miasma clouds.
local schema = {
    id = "magic.miasma_cloud",
    version = 1,
    fields = {
        level_id = {
            type = "int64",
        },

        x = {
            type = "int64",
        },

        y = {
            type = "int64",
        },

        expires_aut = {
            type = "int64",
        },
    },
}

register.component(schema)

return schema

-- Source: player.cc:miasma_player applies a 10-14 turn slow.
local schema = {
    id = "magic.miasma_slow",
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

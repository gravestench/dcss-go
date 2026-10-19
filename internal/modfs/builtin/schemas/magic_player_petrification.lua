-- Source: player.cc:petrify and player-reacts.cc:_decrement_petrification.
local schema = {
    id = "magic.player_petrification",
    version = 1,
    -- Petrifying and petrified are two saved phases with independent remaining durations.
    fields = {
        petrifying_aut = {
            type = "int64",
            default = 0,
        },

        petrified_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

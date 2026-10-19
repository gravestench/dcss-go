-- Source: player.cc:paralyse_player. Duration is in aut and survives saves.
register.component{
    id = "magic.player_paralysis",
    version = 1,
    -- Player paralysis counts aut so effects with different action lengths still expire consistently.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

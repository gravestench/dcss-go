-- Source: spl-selfench.cc:cast_revivification and player.cc:dec_max_hp.
-- Absolute lost HP persists through level gains and transformations.
register.component{
    id = "magic.permanent_hp_loss",
    version = 1,
    -- This absolute loss persists through level gains instead of scaling with current maximum HP.
    fields = {
        amount = {
            type = "int64",
            default = 0,
        },
    },
}

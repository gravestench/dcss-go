register.component{
    id = "projectile.slow",
    version = 1,
    -- Base speed is saved before slowing so the actor can recover its original movement rate.
    fields = {
        base_speed = {
            type = "int64",
            default = 0,
        },

        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

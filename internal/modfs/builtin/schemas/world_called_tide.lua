-- A caster owns its tide; expiry and position survive save/restore.
register.component({
    id = "world.called_tide",
    version = 1,
    fields = {
        start_aut = {
            type = "int64",
            default = 0,
        },
        expires_aut = {
            type = "int64",
            default = 0,
        },
    },
})

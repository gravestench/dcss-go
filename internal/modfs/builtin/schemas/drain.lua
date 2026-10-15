-- Temporary max-HP loss persists through a save and recovers from XP.
register.component{
    id = "status.drain",
    version = 1,
    fields = {
        amount = {
            type = "int64",
            default = 0,
        },
    },
}

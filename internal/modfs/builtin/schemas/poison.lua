-- Monster poison belongs to the affected entity and survives save/restore.
register.component{
    id = "projectile.poison",
    version = 1,
    fields = {
        degree = {
            type = "int64",
            default = 0,
        },

        remaining_aut = {
            type = "int64",
            default = 0,
        },

        max_aut = {
            type = "int64",
            default = 0,
        },

        source = {
            type = "entity",
        },
    },
}

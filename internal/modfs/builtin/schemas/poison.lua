-- Monster poison belongs to the affected entity and survives save/restore.
register.component{
    id = "projectile.poison",
    version = 2,
    -- Degree and elapsed ceiling govern poison damage; source and credit preserve kill attribution.
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

        player_credit = {
            type = "bool",
            default = false,
        },
    },
}

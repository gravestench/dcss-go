-- A thrown net is an ordinary floor item. These components hold only the
-- extra state needed while a monster is trapped; both survive save/restore.
register.component{
    id = "projectile.net",
    version = 1,
    -- Durability stays on the thrown item while the held actor links to that same net entity.
    fields = {
        durability = {
            type = "int64",
            default = 0,
        },
    },
}

register.component{
    id = "projectile.held",
    version = 1,
    fields = {
        net = {
            type = "entity",
        },

        newly_trapped = {
            type = "bool",
            default = true,
        },
    },
}

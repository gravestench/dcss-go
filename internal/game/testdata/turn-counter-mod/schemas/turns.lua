-- The turn counter stores an entity owner alongside its count across save and restore.

register.component{
    id = "mod.turns",
    version = 1,
    fields = {
        count = {
            type = "int64",
            default = 0,
        },

        owner = {
            type = "entity",
        },
    },
}

-- An extra component schema tests save compatibility when a mod adds state.

register.component{
    id = "mod.extra",
    version = 1,
    fields = {
        value = {
            type = "string",
            default = "",
        },
    },
}

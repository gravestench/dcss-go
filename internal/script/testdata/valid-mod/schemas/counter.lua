-- The valid counter schema persists the state updated by the modded system.

register.component{
    id = "test.counter",
    version = 1,
    fields = {
        value = {
            type = "int64",
            default = 0,
        },
    },
}

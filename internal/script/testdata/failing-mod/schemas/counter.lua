-- The counter schema holds mutable state for the intentionally failing system.

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

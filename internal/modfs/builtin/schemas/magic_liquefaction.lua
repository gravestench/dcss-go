local schema = {
    id = "magic.liquefaction",
    version = 1,
    fields = {
        remaining_aut = { type = "int64" },
    },
}

register.component(schema)

return schema

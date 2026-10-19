local schema = {
    id = "magic.liquefaction",
    version = 1,
    -- The player's liquefaction timer controls when transformed ground reverts.
    fields = {
        remaining_aut = { type = "int64" },
    },
}

register.component(schema)

return schema

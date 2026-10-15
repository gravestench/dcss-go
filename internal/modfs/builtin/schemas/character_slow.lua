-- A player has one slow duration regardless of which effect applied it.
local schema = {
    id = "character.slow",
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

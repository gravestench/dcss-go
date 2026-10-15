-- Source: TRAP_GOLUBRIA holds a link to a second floor passage.
local schema = {
    id = "magic.golubria_passage",
    version = 1,
    fields = {
        owner = { type = "entity" },
        pair_id = { type = "int64" },
        level_id = { type = "int64" },
        x = { type = "int64" },
        y = { type = "int64" },
    },
}

register.component(schema)

return schema

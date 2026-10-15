local schema = {
    id = "magic.frozen_ramparts",
    version = 1,
    fields = {
        level_id = { type = "int64" },
        origin_x = { type = "int64" },
        origin_y = { type = "int64" },
        power = { type = "int64" },
        remaining_aut = { type = "int64" },
    },
}

register.component{
    id = "magic.frozen_wall",
    version = 1,
    fields = {
        owner = { type = "entity" },
        level_id = { type = "int64" },
        x = { type = "int64" },
        y = { type = "int64" },
    },
}

register.component(schema)

return schema

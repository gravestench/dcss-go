-- Return location for a player banished from the Dungeon.
register.component{
    id = "world.banishment",
    version = 1,
    fields = {
        origin_level_id = {
            type = "int64",
            default = 0,
        },
        origin_x = {
            type = "int64",
            default = 0,
        },
        origin_y = {
            type = "int64",
            default = 0,
        },
    },
}

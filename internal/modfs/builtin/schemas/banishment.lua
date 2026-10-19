-- Return location for an actor banished from the Dungeon.
register.component{
    id = "world.banishment",
    version = 1,
    -- The origin coordinates let return travel restore the banished actor to its prior Dungeon cell.
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

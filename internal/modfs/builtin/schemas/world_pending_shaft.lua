-- A divine or trap fall is decided in Lua, then carried across the
-- action boundary so the Go session can stage a missing destination map.
register.component{
    id = "world.pending_shaft",
    version = 1,
    fields = {
        origin_level_id = {
            type = "int64",
            default = 0,
        },

        branch_id = {
            type = "string",
            default = "",
        },

        local_depth = {
            type = "int64",
            default = 0,
        },
    },
}

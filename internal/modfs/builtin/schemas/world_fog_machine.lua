-- A fog marker's mutable clock and buildup belong to one saved ECS entity.
-- The source DES record still owns its immutable constructor and location.
local component = require("constants.component")

register.component({
    id = component.FOG_MACHINE,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        x = {
            type = "int64",
            default = 0,
        },
        y = {
            type = "int64",
            default = 0,
        },
        vault_id = {
            type = "string",
            default = "",
        },
        record_index = {
            type = "int64",
            default = 0,
        },
        record_indices = {
            type = "list<int64>",
        },
        positions_x = {
            type = "list<int64>",
        },
        positions_y = {
            type = "list<int64>",
        },
        chain = {
            type = "string",
            default = "",
        },
        listener = {
            type = "string",
            default = "",
        },
        warned = {
            type = "bool",
            default = false,
        },
        kind_id = {
            type = "string",
            default = "",
        },
        walk_dist = {
            type = "int64",
            default = 0,
        },
        pow_min = {
            type = "int64",
            default = 1,
        },
        pow_max = {
            type = "int64",
            default = 0,
        },
        pow_rolls = {
            type = "int64",
            default = 3,
        },
        delay_min = {
            type = "int64",
            default = 0,
        },
        delay_max = {
            type = "int64",
            default = 0,
        },
        size_min = {
            type = "int64",
            default = 0,
        },
        size_max = {
            type = "int64",
            default = 0,
        },
        size_buildup_amnt = {
            type = "int64",
            default = 0,
        },
        size_buildup_time = {
            type = "int64",
            default = 1,
        },
        spread_rate = {
            type = "int64",
            default = -1,
        },
        spread_buildup_amnt = {
            type = "int64",
            default = 0,
        },
        spread_buildup_time = {
            type = "int64",
            default = 1,
        },
        start_clouds = {
            type = "int64",
            default = 1,
        },
        exclusion_radius = {
            type = "int64",
            default = 1,
        },
        countdown_aut = {
            type = "int64",
            default = 0,
        },
        buildup_aut = {
            type = "int64",
            default = 0,
        },
    },
})

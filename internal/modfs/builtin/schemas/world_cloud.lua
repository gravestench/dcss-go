-- A cloud owns a cell and records damage credit independent of source life.
local component = require("constants.component")

register.component({
    id = component.WORLD_CLOUD,
    version = 1,
    fields = {
        kind_id = {
            type = "string",
            default = "",
        },
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
        decay_aut = {
            type = "int64",
            default = 0,
        },
        spread_rate = {
            type = "int64",
            default = 0,
        },
        exclusion_radius = {
            type = "int64",
            default = 0,
        },
        source_actor_id = {
            type = "uint64",
            default = 0,
        },
        kill_category = {
            type = "string",
            default = "",
        },
        killer_type = {
            type = "string",
            default = "",
        },
        opaque = {
            type = "bool",
            default = false,
        },
        special_ints = {
            type = "map<string,int64>",
        },
    },
})

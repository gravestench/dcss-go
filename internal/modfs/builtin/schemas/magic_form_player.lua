-- Source: transform.cc:DUR_TRANSFORMATION and TRANSFORM_POW_KEY.
local schema = {
    id = "magic.player_form",
    version = 1,
    fields = {
        form_id = {
            type = "string",
            default = "",
        },

        remaining_aut = {
            type = "int64",
            default = 0,
        },

        power = {
            type = "int64",
            default = 0,
        },

        appendage_mask = {
            type = "int64",
            default = 0,
        },
        uncancellable = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

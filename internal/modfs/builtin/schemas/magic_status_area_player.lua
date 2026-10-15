-- Source: duration-data.h and spl-selfench.cc/spl-damage.cc area durations.
local schema = {
    id = "magic.area_status",
    version = 1,
    fields = {
        corpse_rot_aut = {
            type = "int64",
            default = 0,
        },

        corpse_rot_power = {
            type = "int64",
            default = 0,
        },

        toxic_radiance_aut = {
            type = "int64",
            default = 0,
        },

        toxic_radiance_power = {
            type = "int64",
            default = 0,
        },

        noxious_bog_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

-- Source: duration-data.h and spl-selfench.cc. Aut and phase are saved so
-- expiry and the second half of Swiftness continue after restore.
local schema = {
    id = "magic.player_status",
    version = 1,
    fields = {
        swift_aut = {
            type = "int64",
            default = 0,
        },

        swift_return_aut = {
            type = "int64",
            default = 0,
        },

        swift_phase = {
            type = "int64",
            default = 0,
        },

        wereblood_aut = {
            type = "int64",
            default = 0,
        },

        wereblood_bonus = {
            type = "int64",
            default = 0,
        },

        silence_aut = {
            type = "int64",
            default = 0,
        },

        lowered_will_aut = {
            type = "int64",
            default = 0,
        },

        ice_armour_aut = {
            type = "int64",
            default = 0,
        },

        ice_armour_power = {
            type = "int64",
            default = 0,
        },

        death_door_aut = {
            type = "int64",
            default = 0,
        },

        death_door_hp = {
            type = "int64",
            default = 0,
        },

        death_door_cooldown_aut = {
            type = "int64",
            default = 0,
        },

        blink_cooldown_aut = {
            type = "int64",
            default = 0,
        },

        confusing_touch_aut = {
            type = "int64",
            default = 0,
        },

        confusing_touch_power = {
            type = "int64",
            default = 0,
        },

        portal_projectile_aut = {
            type = "int64",
            default = 0,
        },

        portal_projectile_power = {
            type = "int64",
            default = 0,
        },

        disjunction_aut = {
            type = "int64",
            default = 0,
        },

        vertigo_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

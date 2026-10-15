-- Source: player-act.cc:go_berserk, player.cc:player_end_berserk.
local component = require("constants.component")

local schema = {
    id = component.RAGE,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
        cooldown_aut = {
            type = "int64",
            default = 0,
        },
        noncombat_actions = {
            type = "int64",
            default = 0,
        },
        attacked_this_turn = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

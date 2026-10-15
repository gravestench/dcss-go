-- player.cc:magic_contamination is saved on the player.
local ids = require("policy.magic.effects.zaps.ids")

local contamination = {}

register.component{
    id = ids.component.CONTAMINATION,
    version = 1,
    fields = {
        amount = {
            type = "int64",
            default = 0,
        },
    },
}

return contamination

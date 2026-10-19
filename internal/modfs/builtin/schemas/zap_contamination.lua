-- player.cc:magic_contamination is saved on the player.
local ids = require("policy.magic.effects.zaps.ids")

local contamination = {}

register.component{
    id = ids.component.CONTAMINATION,
    version = 1,
    -- Contamination amount stays on the player across spells until decay or mutation effects consume it.
    fields = {
        amount = {
            type = "int64",
            default = 0,
        },
    },
}

return contamination

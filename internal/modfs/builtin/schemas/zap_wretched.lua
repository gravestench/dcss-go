-- mon-ench.cc:ENCH_WRETCHED is saved on the affected monster.
local ids = require("policy.magic.effects.zaps.ids")

local wretched = {}

register.component{
    id = ids.component.WRETCHED,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

return wretched

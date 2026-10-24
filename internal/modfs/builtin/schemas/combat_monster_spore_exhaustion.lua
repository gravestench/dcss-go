-- Spore melee permanently spends one of the attacker's hit dice on each
-- breathing contact. This record is separate from the summoned spore's
-- target and explosion state, and survives floor travel and save/restore.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_SPORE_EXHAUSTION,
    version = 1,
    fields = {
        lost_hd = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

-- A Doom Howl arrival is permanent, so it cannot masquerade as a timed
-- summon. Its saved origin admits it outside the scenario's initial roster.
local ids = require("policy.combat.monster_doom_howl.ids")

local schema = {
    id = ids.ARRIVAL,
    version = 1,
    fields = {
        created_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

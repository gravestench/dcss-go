-- A soul mark belongs to its living target and survives save/restore until
-- its expiry or death. Caster ID is numeric because the caster may die first.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_BOUND_SOUL,
    version = 1,
    fields = {
        caster_id = {
            type = "uint64",
            default = 0,
        },
        expires_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

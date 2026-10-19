-- The caster owns the awakened forest timer. Tree cells remain grid terrain;
-- no level global or duplicate set of tree entities is saved.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_AWAKE_FOREST,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

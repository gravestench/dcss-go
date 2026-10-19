local component = require("constants.component")

-- A caster owns the remaining aura time; the level's cloud restriction is
-- derived from living casters, so death and travel cannot leave a stale flag.
local schema = {
    id = component.MONSTER_STILL_WINDS,
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

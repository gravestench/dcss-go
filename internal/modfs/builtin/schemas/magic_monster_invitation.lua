local component = require("constants.component")

-- Forceful Invitation chooses one branch for each caster, then reuses it.
-- This saved component keeps later casts stable across save and restore.
local schema = {
    id = component.MONSTER_INVITATION,
    version = 1,
    fields = {
        branch_id = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema

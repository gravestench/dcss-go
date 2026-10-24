-- A draconian job combines its class with a colored base. The base is actor
-- state because authored vaults can choose a color different from the job's
-- ordinary source default, and the actor can later leave its vault.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_DRACONIAN_BASE,
    version = 1,
    fields = {
        base_id = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema

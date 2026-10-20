local component = require("constants.component")

-- A merged slime is one actor with several bodies. Vault names and
-- Planerend both set this size; HP, melee damage, and display read it.
local schema = {
    id = component.SLIME_BLOB,
    version = 1,
    fields = {
        size = {
            type = "int64",
            default = 1,
        },
    },
}

register.component(schema)

return schema

local component = require("constants.component")

-- A merged slime is one actor with several bodies. Vault names and
-- Planerend both set this size; HP, melee damage, and display read it.
local schema = {
    id = component.SLIME_BLOB,
    version = 2,
    fields = {
        size = {
            type = "int64",
            default = 1,
        },
        -- Splitting rounds HP; merging pools possibly different authored
        -- rolls. The resulting maximum is no longer fixed HP times size.
        reshaped_max = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

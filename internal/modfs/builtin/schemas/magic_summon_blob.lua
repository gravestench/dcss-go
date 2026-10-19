local component = require("constants.component")

-- Planerend creates a large slime creature. Size belongs to this summoned
-- actor rather than the shared monster catalog or the casting module.
local schema = {
    id = component.SUMMON_BLOB,
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

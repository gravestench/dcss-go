local component = require("constants.component")

-- Source: ENCH_WATER_HOLD stores its holder and accrued duration on the
-- engulfed monster. The status survives turns and save/restore.
local schema = {
    id = component.WATER_HOLD,
    version = 1,
    -- The engulfed actor stores its holder and accrued hold time for damage and escape checks.
    fields = {
        by = {
            type = "entity",
        },
        elapsed_aut = {
            type = "int64",
            default = 1,
        },
    },
}

register.component(schema)

return schema

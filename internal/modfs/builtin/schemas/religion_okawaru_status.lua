-- Heroism and Finesse have independent source timers, but one patron owns
-- both. Their remaining aut persists independently through save/restore.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_OKAWARU_STATUS,
    version = 1,
    fields = {
        heroism_aut = {
            type = "int64",
            default = 0,
        },
        finesse_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

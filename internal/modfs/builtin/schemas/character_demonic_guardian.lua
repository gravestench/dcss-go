local component = require("constants.component")

local schema = {
    id = component.DEMONIC_GUARDIAN,
    version = 1,
    -- The cooldown prevents repeated guardian summons while an earlier trigger is still recovering.
    fields = {
        cooldown_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

local component = require("constants.component")

-- Haunt wraiths remember their original victim. The target is actor state,
-- not a module variable, so save/restore and AI can continue the pursuit.
local schema = {
    id = component.SUMMON_HAUNTING,
    version = 1,
    fields = {
        target = {
            type = "entity",
        },
    },
}

register.component(schema)

return schema

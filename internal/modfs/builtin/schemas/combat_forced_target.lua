-- A forced target belongs to one monster action. Ru may redirect a hostile
-- attack to a same-side body; the action owner removes this after resolving.
local component = require("constants.component")

local schema = {
    id = component.COMBAT_FORCED_TARGET,
    version = 1,
    fields = {
        target = {
            type = "entity",
        },
    },
}

register.component(schema)

return schema

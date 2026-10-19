local component = require("constants.component")

-- The pinned source does not age ENCH_REPEL_MISSILES each monster action.
-- This saved marker therefore lasts until Unravelling or actor removal.
local schema = {
    id = component.MONSTER_REPULSION,
    version = 1,
    fields = {
        active = {
            type = "bool",
            default = true,
        },
    },
}

register.component(schema)

return schema

local component = require("constants.component")
local restrictions = require("constants.safety_restrictions")

-- Source: DUR_NO_POTIONS and DUR_NO_SCROLLS persist independently.
local schema = {
    id = component.DAMAGE_SAFETY,
    version = 1,
    fields = {
        [restrictions.POTIONS] = {
            type = "int64",
            default = 0,
        },

        [restrictions.SCROLLS] = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

local component = require("constants.component")
local restrictions = require("constants.safety_restrictions")

-- Source: DUR_NO_POTIONS and DUR_NO_SCROLLS persist independently.
local schema = {
    id = component.DAMAGE_SAFETY,
    version = 1,
    -- Potion and scroll locks expire independently after damage; each restriction stores its own remaining aut.
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

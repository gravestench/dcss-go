local component = require("constants.component")

-- Source: DUR_SANGUINE_ARMOUR persists its remaining action time.
local schema = {
    id = component.SANGUINE_ARMOUR,
    version = 1,
    -- Recent damage refreshes this aut timer; armour calculations read it without owning the timer.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

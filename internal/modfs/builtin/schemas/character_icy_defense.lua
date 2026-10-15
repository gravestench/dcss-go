local component = require("constants.component")

-- Source: DUR_ICEMAIL_DEPLETED is shared by Icemail and Condensation Shield.
local schema = {
    id = component.ICY_DEFENSE,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

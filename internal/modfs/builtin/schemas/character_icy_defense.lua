local component = require("constants.component")

-- Source: DUR_ICEMAIL_DEPLETED is shared by Icemail and Condensation Shield.
local schema = {
    id = component.ICY_DEFENSE,
    version = 1,
    -- One depletion timer covers both Icemail and Condensation Shield after fire melts their protection.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

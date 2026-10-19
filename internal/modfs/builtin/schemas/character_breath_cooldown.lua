local component = require("constants.component")

local schema = {
    id = component.BREATH_COOLDOWN,
    version = 1,
    -- All breath abilities consult one timer so a breath attack cannot bypass recovery by changing forms.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

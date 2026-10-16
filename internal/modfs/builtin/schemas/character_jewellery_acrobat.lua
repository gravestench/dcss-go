local component = require("constants.component")

-- Source: player.cc:update_acrobat_status keeps the move/wait bonus through
-- the resulting monster response, then the next player action replaces it.
local schema = {
    id = component.JEWELLERY_ACROBAT,
    version = 1,
    fields = {
        active = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

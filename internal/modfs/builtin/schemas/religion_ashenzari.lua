-- Ashenzari's curse offer is saved separately from common worship. Later
-- curse systems can consume the pending offer without re-running conversion.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_ASHENZARI,
    version = 1,
    fields = {
        curse_progress = {
            type = "int64",
            default = 0,
        },
        curse_delay = {
            type = "int64",
            default = 20,
        },
        offer_pending = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

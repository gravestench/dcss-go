-- Each orc remembers whether Beogh offered conversion and whether it became
-- a permanent god gift. Its real side can later turn hostile under wrath or
-- desertion without erasing provenance or a separate band leader link.
local attitudes = require("constants.attitude")
local component = require("constants.component")

local schema = {
    id = component.BEOGH_ORC,
    version = 2,
    fields = {
        attitude = {
            type = "string",
            default = attitudes.HOSTILE,
        },

        attempted = {
            type = "bool",
            default = false,
        },

        gift = {
            type = "bool",
            default = false,
        },

        gift_category = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema

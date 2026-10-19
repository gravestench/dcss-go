local component = require("constants.component")

-- Source: PALENTONGA_CURL_KEY remains set across the monster phase and is
-- cleared before the next one. It must survive a save during that interval.
local schema = {
    id = component.CURL,
    version = 1,
    -- The active bit spans the monster response to the hit that triggered Palentonga curling.
    fields = {
        active = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

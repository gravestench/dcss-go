-- An acquirement scroll keeps its generated choices across save and cancel.
local component = require("constants.component")

local schema = {
    id = component.SCROLL_ACQUIREMENT,
    version = 2,
    -- Generated offer IDs remain fixed if the player cancels and later reopens acquirement.
    fields = {
        offer_ids = {
            type = "list<entity>",
        },
    },
}

register.component(schema)

return schema

-- Beogh's recall list and delay belong to one player action sequence.
-- Saving entity handles lets a restored queue continue in source order.
local component = require("constants.component")

local schema = {
    id = component.BEOGH_RECALL,
    version = 1,
    fields = {
        queue = {
            type = "list<entity>",
        },

        next_index = {
            type = "int64",
            default = 1,
        },

        next_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

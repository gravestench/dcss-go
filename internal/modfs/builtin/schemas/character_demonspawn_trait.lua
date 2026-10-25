-- Each entity is one future or acquired Demonspawn mutation grant. Keeping
-- facet and rank lets restore verify the schedule without rerolling it.
local component = require("constants.component")

local schema = {
    id = component.DEMONSPAWN_TRAIT,
    version = 1,
    fields = {
        owner = {
            type = "entity",
        },
        facet_id = {
            type = "string",
            default = "",
        },
        rank_index = {
            type = "int64",
            default = 0,
        },
        mutation_id = {
            type = "string",
            default = "",
        },
        level = {
            type = "int64",
            default = 0,
        },
        granted = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

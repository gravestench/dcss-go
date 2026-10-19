local component = require("constants.component")

local schema = {
    id = component.ZOT_CLOCK,
    version = 1,
    -- Branch aut totals and visited-floor flags prevent clock progress from resetting on level travel.
    fields = {
        branch_aut = {
            type = "map<string,int64>",
        },

        visited_floors = {
            type = "map<string,bool>",
        },
    },
}

register.component(schema)

return schema

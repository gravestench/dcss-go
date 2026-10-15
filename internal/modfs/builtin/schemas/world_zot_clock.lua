local component = require("constants.component")

local schema = {
    id = component.ZOT_CLOCK,
    version = 1,
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

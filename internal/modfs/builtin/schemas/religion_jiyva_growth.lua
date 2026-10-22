-- A slime's source meal can grow max HP beyond the population roll, and a
-- later split can halve it below that roll. Save validation needs the
-- original profile and split lineage to distinguish these from corruption.
local component = require("constants.component")

local schema = {
    id = component.JIYVA_GROWTH,
    version = 1,
    fields = {
        birth_max = {
            type = "int64",
            default = 0,
        },

        split_count = {
            type = "int64",
            default = 0,
        },

        born_from_split = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

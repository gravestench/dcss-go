-- Natasha's remaining lives belong to her current actor. A replacement
-- body inherits the count, while unrelated source uniques have no record.
local component = require("constants.component")

local schema = {
    id = component.UNIQUE_REVIVAL,
    version = 1,
    fields = {
        revives = {
            type = "uint64",
        },
    },
}

register.component(schema)

return schema

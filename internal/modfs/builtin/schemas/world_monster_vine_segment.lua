-- Each visible connector belongs to one vine head. Its path index lets
-- save/restore retain a chain instead of rediscovering a global object.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_VINE_SEGMENT,
    version = 1,
    fields = {
        head = {
            type = "entity",
        },
        index = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

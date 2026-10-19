-- A vine's anchor is saved on that vine, alongside the shared summon owner.
-- Its head may move, but losing sight of its awakener ends the summon.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_VINE,
    version = 2,
    fields = {
        target = {
            type = "entity",
        },
        anchor_x = {
            type = "int64",
            default = 0,
        },
        anchor_y = {
            type = "int64",
            default = 0,
        },
        pull_x = {
            type = "int64",
            default = 0,
        },
        pull_y = {
            type = "int64",
            default = 0,
        },
        pull_pending = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

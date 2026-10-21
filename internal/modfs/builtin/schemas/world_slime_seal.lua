-- One saved cell links a source clear stone wall to its release state.
-- Keeping a marker after the wall falls lets restore verify the event.
local component = require("constants.component")

local schema = {
    id = component.SLIME_SEAL,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        x = {
            type = "int64",
            default = 0,
        },
        y = {
            type = "int64",
            default = 0,
        },
        record_index = {
            type = "int64",
            default = 0,
        },
        released = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema

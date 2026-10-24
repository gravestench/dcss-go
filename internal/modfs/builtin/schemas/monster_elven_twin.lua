-- The bereavement record belongs to the surviving actor. A pending
-- reaction can outlive the current floor and resumes after save/restore.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_ELVEN_TWIN,
    version = 1,
    fields = {
        grieved = {
            type = "bool",
            default = false,
        },

        pending = {
            type = "bool",
            default = false,
        },

        energized = {
            type = "bool",
            default = false,
        },

        can_climb = {
            type = "bool",
            default = false,
        },

        cause = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema

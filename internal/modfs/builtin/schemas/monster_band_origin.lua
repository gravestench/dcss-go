-- A follower keeps its originating band after the leader dies or changes
-- floors. The marker distinguishes an authored band member from a normal
-- population roll during save validation.
local component = require("constants.component")

local schema = {
    id = component.BAND_ORIGIN,
    version = 1,
    fields = {
        leader_kind_id = {
            type = "string",
        },
        member_kind_id = {
            type = "string",
        },
    },
}

register.component(schema)

return schema

local component = require("constants.component")

local schema = {
    id = component.PLAYER_UNIQUE_HISTORY,
    version = 2,
    -- Unique generation state persists separately from living actors so a killed unique is not selected again.
    fields = {
        status = {
            type = "map<string,string>",
        },
        -- Monster claims persist after death or travel, so a later level
        -- cannot reselect the same named creature from a different vault.
        monsters = {
            type = "map<string,bool>",
        },
    },
}

register.component(schema)

return schema

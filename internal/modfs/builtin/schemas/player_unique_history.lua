local component = require("constants.component")

local schema = {
    id = component.PLAYER_UNIQUE_HISTORY,
    version = 5,
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
        -- Ignacio's Pan chance/coinflip is decided once for the whole run.
        -- The value is a named allow/forbid state, not a transient veto draw.
        pan_states = {
            type = "map<string,string>",
        },
        -- A unique's run-wide placement choice must survive level changes.
        -- The Serpent of Hell uses this to keep one chosen Hell ending.
        choices = {
            type = "map<string,string>",
        },
        -- Boris can be generated again after a real death. This run flag
        -- distinguishes that permission from his first authored placement.
        boris_killed = {
            type = "bool",
        },
    },
}

register.component(schema)

return schema

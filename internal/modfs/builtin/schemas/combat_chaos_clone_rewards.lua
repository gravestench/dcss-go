-- Chaos clones can grant real XP after they die. Preserve that extra XP so
-- the population save bound does not mistake it for impossible Dungeon kills.
local component = require("constants.component")

local schema = {
    id = component.CHAOS_CLONE_REWARDS,
    version = 1,
    fields = {
        earned_xp = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

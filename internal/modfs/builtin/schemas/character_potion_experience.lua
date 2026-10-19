-- Source: potion.cc:PotionExperience. Level XP and skill XP have
-- separate ledgers; the saved offsets keep restore validation exact.
local component = require("constants.component")

local schema = {
    id = component.POTION_EXPERIENCE,
    version = 1,
    -- Level XP and bonus skill XP remain distinct, with pending skill XP awaiting the training choice.
    fields = {
        untrained_level_xp = {
            type = "int64",
            default = 0,
        },
        bonus_skill_xp = {
            type = "int64",
            default = 0,
        },
        pending_skill_xp = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

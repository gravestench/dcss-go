-- A monster's toxic aura survives save/restore and follows its moving body.
-- Player Toxic Radiance uses AREA_STATUS because it shares that player's
-- area timer record with Corpse Rot and Noxious Bog.
local component = require("constants.component")

local schema = {}

register.component({
    id = component.MONSTER_TOXIC_RADIANCE,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
        power = {
            type = "int64",
            default = 0,
        },
    },
})

return schema

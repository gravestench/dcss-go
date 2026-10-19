-- The avatar's continuing song is tied to the caster, not the player. Its
-- pull and drowned-soul call must resume after save/restore.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_AVATAR_SONG,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
        called = {
            type = "bool",
            default = false,
        },
        last_player_x = {
            type = "int64",
            default = 0,
        },
        last_player_y = {
            type = "int64",
            default = 0,
        },
        last_level_id = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema

-- One Tomb marker links its temporary walls to their saved center so the
-- entire wall group can dissolve if its occupant leaves before timeout.
local component = require("constants.component")

register.component({
    id = component.RELIGION_CARD_TOMB,
    version = 1,
    fields = {
        owner = {
            type = "entity",
        },
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
        expires_aut = {
            type = "int64",
            default = 0,
        },
        wall_markers = {
            type = "list<entity>",
            default = {},
        },
    },
})

-- black smoke (ids.CLOUD_BLACK_SMOKE) has spread rate 22 and is harmless to occupants.
-- Placement and aging use this record; exposure skips its occupant effect.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_BLACK_SMOKE,
    name = "black smoke",
    color = "DARKGREY",
    opaque = true,
    harmless = true,
    spread_rate = 22,
    -- Zero damage, opacity, and spread are field data; harmless exposure skips contact.
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.smoke",
}

register.definition(categories.CLOUDS, definition)

return definition

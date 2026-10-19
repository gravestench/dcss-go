-- salt (ids.CLOUD_SALT) has spread rate 0 and is harmless to occupants.
-- Placement and aging use this record; exposure skips its occupant effect.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_SALT,
    name = "salt",
    color = "ETC_AIR",
    opaque = true,
    harmless = true,
    spread_rate = 0,
    -- Zero damage, opacity, and spread are field data; harmless exposure skips contact.
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.salt",
}

register.definition(categories.CLOUDS, definition)

return definition

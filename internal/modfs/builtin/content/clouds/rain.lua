-- rain (ids.CLOUD_RAIN) has spread rate 11 and delegates contact to
-- policy.clouds.effects.rain.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_RAIN,
    name = "rain",
    verbose_name = "the rain",
    color = "ETC_MIST",
    opaque = false,
    harmless = false,
    spread_rate = 11,
    -- rain damage is rolled at contact, so the catalog stores a formula rather
    -- than a prior result.
    damage = {
        base = 0,
        random = 9,
        extra_player = false,
    },
    effect = "policy.clouds.effects.rain",
}

register.definition(categories.CLOUDS, definition)

return definition

-- thunder (ids.CLOUD_STORM) has spread rate 0 and delegates contact to
-- policy.clouds.effects.storm.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_STORM,
    name = "thunder",
    verbose_name = "a thunderstorm",
    color = "ETC_DARK",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    -- thunder damage is rolled at contact, so the catalog stores a formula rather
    -- than a prior result.
    damage = {
        base = 12,
        random = 12,
        extra_player = false,
    },
    effect = "policy.clouds.effects.storm",
}

register.definition(categories.CLOUDS, definition)

return definition

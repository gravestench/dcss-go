-- seething chaos (ids.CLOUD_CHAOS) has spread rate 0 and delegates contact to
-- policy.clouds.effects.chaos.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_CHAOS,
    name = "seething chaos",
    color = "ETC_RANDOM",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    -- Direct damage is zero; the effect module may apply a status or terrain change.
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.chaos",
}

register.definition(categories.CLOUDS, definition)

return definition

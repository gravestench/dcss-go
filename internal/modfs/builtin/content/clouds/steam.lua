-- steam (ids.CLOUD_STEAM) has spread rate 22 and delegates contact to
-- policy.clouds.effects.steam.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_STEAM,
    name = "steam",
    verbose_name = "a cloud of scalding steam",
    color = "LIGHTGREY",
    opaque = true,
    harmless = false,
    spread_rate = 22,
    -- steam damage is rolled at contact, so the catalog stores a formula rather
    -- than a prior result.
    damage = {
        base = 0,
        random = 16,
        extra_player = false,
    },
    effect = "policy.clouds.effects.steam",
}

register.definition(categories.CLOUDS, definition)

return definition

-- spreading flames (ids.CLOUD_FOREST_FIRE) has spread rate 0 and delegates
-- contact to policy.clouds.effects.forest_fire.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_FOREST_FIRE,
    name = "spreading flames",
    verbose_name = "a forest fire",
    color = "COLOUR_UNDEF",
    console_color = "LIGHTRED",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    -- spreading flames damage is rolled at contact, so the catalog stores a
    -- formula rather than a prior result.
    damage = {
        base = 6,
        random = 16,
        extra_player = true,
    },
    effect = "policy.clouds.effects.forest_fire",
}

register.definition(categories.CLOUDS, definition)

return definition

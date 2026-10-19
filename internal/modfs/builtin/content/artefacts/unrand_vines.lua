-- robe of Vines (artefact_ids.UNRAND_VINES) is a unique artefact based on
-- item_ids.ARM_ROBE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_VINES,
    name = "robe of Vines",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "NoPotionHeal",
    description = "Its wearer cannot be healed by potions.",
    brand_description = "",
    colour = "GREEN",
    tile = "urand_vines",
    tile_equipment = "vines",
    type = "",
    flags = {
    },
    -- robe of Vines properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 1,
        regen = 4,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

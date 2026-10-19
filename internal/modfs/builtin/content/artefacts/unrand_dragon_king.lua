-- scales of the Dragon King (artefact_ids.UNRAND_DRAGON_KING) is a unique
-- artefact based on item_ids.ARM_GOLD_DRAGON_ARMOUR.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DRAGON_KING,
    name = "scales of the Dragon King",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GOLD_DRAGON_ARMOUR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "urand_dragon_king",
    tile_equipment = "dragonarm_gold",
    type = "",
    flags = {
    },
    -- scales of the Dragon King properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 9,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

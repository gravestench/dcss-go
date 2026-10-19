-- boots of the spider (artefact_ids.UNRAND_SPIDER) is a unique artefact based
-- on item_ids.ARM_BOOTS.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_SPIDER,
    name = "boots of the spider",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BOOTS,
    fallback = "",
    brand = armour_egos.JUMPING,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTMAGENTA",
    tile = "urand_spider",
    tile_equipment = "spider",
    type = "",
    flags = {
        "nogen",
    },
    -- boots of the spider properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 3,
        stealth = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

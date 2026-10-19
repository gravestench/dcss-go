-- faerie dragon scales (artefact_ids.UNRAND_FAERIE) is a unique artefact
-- based on item_ids.ARM_ACID_DRAGON_ARMOUR.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FAERIE,
    name = "faerie dragon scales",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ACID_DRAGON_ARMOUR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_JEWEL",
    tile = "urand_faerie",
    tile_equipment = "faerie_dragon_armour",
    type = "",
    flags = {
        "nogen",
        "no_upgrade",
    },
    -- faerie dragon scales properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 3,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

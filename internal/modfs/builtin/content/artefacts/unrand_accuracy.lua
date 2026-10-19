-- knife of Accuracy (artefact_ids.UNRAND_ACCURACY) is a unique artefact based
-- on item_ids.WPN_DAGGER.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ACCURACY,
    name = "knife of Accuracy",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DAGGER,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTCYAN",
    tile = "urand_knife_of_accuracy",
    tile_equipment = "knife_of_accuracy",
    type = "knife",
    flags = {
        "tilerim",
        "nogen",
    },
    -- knife of Accuracy properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 27,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

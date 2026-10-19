-- Maxwell's etheric cage (artefact_ids.UNRAND_ETHERIC_CAGE) is a unique
-- artefact based on item_ids.ARM_HELMET.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ETHERIC_CAGE,
    name = "Maxwell's etheric cage",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HELMET,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "RegenMP+",
    description = "",
    brand_description = "",
    colour = "ETC_ELECTRICITY",
    tile = "urand_etheric_cage",
    tile_equipment = "etheric_cage",
    type = "",
    flags = {
        "mutate",
        "elec",
        "chaotic",
        "nogen",
    },
    -- Maxwell's etheric cage properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        mp = 4,
        plus = 0,
        value = 400,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- orange crystal plate armour
-- (artefact_ids.UNRAND_ORANGE_CRYSTAL_PLATE_ARMOUR) is a unique artefact
-- based on item_ids.ARM_CRYSTAL_PLATE_ARMOUR.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_ORANGE_CRYSTAL_PLATE_ARMOUR,
    name = "orange crystal plate armour",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CRYSTAL_PLATE_ARMOUR,
    fallback = "",
    brand = armour_egos.ARCHMAGI,
    fallback_brand = brands.NORMAL,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_orange_crystal",
    tile_equipment = "orange_crystal",
    type = "",
    flags = {
        "clarity",
    },
    -- orange crystal plate armour properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        int = 3,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

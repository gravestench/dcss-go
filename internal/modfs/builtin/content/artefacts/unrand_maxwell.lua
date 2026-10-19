-- Maxwell's patent armour (artefact_ids.UNRAND_MAXWELL) is a unique artefact
-- based on item_ids.ARM_PLATE_ARMOUR.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_MAXWELL,
    name = "Maxwell's patent armour",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_PLATE_ARMOUR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTGREEN",
    tile = "urand_maxwell",
    tile_equipment = "maxwell",
    type = "",
    flags = {
        "nospell",
        "notelep",
        "elec",
        "rCorr",
    },
    -- Maxwell's patent armour properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 15,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

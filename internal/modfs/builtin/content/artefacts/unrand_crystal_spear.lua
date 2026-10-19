-- Lehudib's crystal spear (artefact_ids.UNRAND_CRYSTAL_SPEAR) is a unique
-- artefact based on item_ids.WPN_SPEAR.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_CRYSTAL_SPEAR,
    name = "Lehudib's crystal spear",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SPEAR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "GREEN",
    tile = "urand_crystal_spear",
    tile_equipment = "crystal_spear",
    type = "",
    flags = {
        "nogen",
    },
    -- Lehudib's crystal spear properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        int = 3,
        plus = 6,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

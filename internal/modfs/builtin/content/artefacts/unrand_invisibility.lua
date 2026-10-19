-- amulet of invisibility (artefact_ids.UNRAND_INVISIBILITY) is a unique
-- artefact based on item_ids.AMU_NOTHING.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_INVISIBILITY,
    name = "amulet of invisibility",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "WHITE",
    tile = "urand_cekugob",
    tile_equipment = "",
    type = "",
    flags = {
        "inv",
        "nogen",
    },
    -- amulet of invisibility properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

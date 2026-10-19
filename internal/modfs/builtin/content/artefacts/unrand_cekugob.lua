-- amulet of Cekugob (artefact_ids.UNRAND_CEKUGOB) is a unique artefact based
-- on item_ids.AMU_ACROBAT.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_CEKUGOB,
    name = "amulet of Cekugob",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_ACROBAT,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_SILVER",
    tile = "urand_cekugob",
    tile_equipment = "",
    type = "",
    flags = {
        "elec",
        "poison",
        "notelep",
        "nogen",
    },
    -- amulet of Cekugob properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        ac = 1,
        ev = 1,
        life = 2,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1083

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_CEKUGOB,
    name = "amulet of Cekugob",
    source_order = 74,
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

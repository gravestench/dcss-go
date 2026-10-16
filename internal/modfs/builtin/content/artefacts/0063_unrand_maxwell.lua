-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:958

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_MAXWELL,
    name = "Maxwell's patent armour",
    source_order = 63,
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

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1370

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_FIRESTARTER,
    name = "great mace \"Firestarter\"",
    source_order = 100,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_MACE,
    fallback = "",
    brand = brands.FLAMING,
    fallback_brand = "",
    appearance = "",
    inscription = "inner flame,",
    description = "It grants immunity to clouds of flame.",
    brand_description =
        "It burns those it strikes, dealing additional fire damage.\n+\n+It fills those it strikes with an explosiv" ..
        "e inner flame.",
    colour = "RED",
    tile = "urand_firestarter",
    tile_equipment = "firestarter",
    type = "",
    flags = {
        "skip_ego",
    },
    properties = {
        fire = 2,
        plus = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

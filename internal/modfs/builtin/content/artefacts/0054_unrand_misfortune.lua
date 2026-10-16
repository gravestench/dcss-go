-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:850

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_MISFORTUNE,
    name = "robe of Misfortune",
    source_order = 54,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = armour_egos.PONDEROUSNESS,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTMAGENTA",
    tile = "urand_misfortune",
    tile_equipment = "robe_misfortune",
    type = "",
    flags = {
        "harm",
        "slow",
        "corrode",
    },
    properties = {
        ev = 5,
        plus = 5,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

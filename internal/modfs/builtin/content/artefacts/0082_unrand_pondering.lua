-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1148

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_PONDERING,
    name = "hat of Pondering",
    source_order = 82,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = armour_egos.PONDEROUSNESS,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_pondering",
    tile_equipment = "wizard_bluegreen",
    type = "",
    flags = {
    },
    properties = {
        int = 5,
        mp = 10,
        plus = 3,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

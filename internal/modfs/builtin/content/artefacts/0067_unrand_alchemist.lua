-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1000

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ALCHEMIST,
    name = "hat of the Alchemist",
    source_order = 67,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTMAGENTA",
    tile = "urand_alchemist",
    tile_equipment = "turban_purple",
    type = "",
    flags = {
        "elec",
        "poison",
        "rMut",
        "rCorr",
    },
    properties = {
        cold = 1,
        fire = 1,
        life = 1,
        plus = -2,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

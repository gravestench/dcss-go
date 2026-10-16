-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:439

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_CHILLY_DEATH,
    name = "dagger of Chilly Death",
    source_order = 21,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DAGGER,
    fallback = "",
    brand = brands.FREEZING,
    fallback_brand = "",
    appearance = "",
    inscription = "flash freeze,",
    description = "",
    brand_description = "",
    colour = "ETC_ICE",
    tile = "urand_chilly_death",
    tile_equipment = "chilly_death",
    type = "",
    flags = {
        "poison",
        "skip_ego",
        "nogen",
    },
    properties = {
        cold = 2,
        fire = -1,
        plus = 9,
        will = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

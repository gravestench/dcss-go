-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:397

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_FLAMING_DEATH,
    name = "scimitar of Flaming Death",
    source_order = 18,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SCIMITAR,
    fallback = "",
    brand = brands.FLAMING,
    fallback_brand = "",
    appearance = "",
    inscription = "sticky flame,",
    description = "",
    brand_description = "",
    colour = "ETC_FIRE",
    tile = "urand_flaming_death",
    tile_equipment = "flaming_death",
    type = "",
    flags = {
        "poison",
        "skip_ego",
        "nogen",
    },
    properties = {
        cold = -1,
        fire = 2,
        plus = 6,
        will = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

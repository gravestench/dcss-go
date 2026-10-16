-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:595

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_OCTOPUS_KING,
    name = "trident of the Octopus King",
    source_order = 33,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_TRIDENT,
    fallback = "",
    brand = brands.VENOM,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_WATER",
    tile = "urand_octopus_king",
    tile_equipment = "trident_octopus_king",
    type = "",
    flags = {
        "elec",
        "poison",
        "no_upgrade",
    },
    properties = {
        plus = 8,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

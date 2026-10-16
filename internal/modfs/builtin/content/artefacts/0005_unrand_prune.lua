-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:232

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_PRUNE,
    name = "glaive of Prune",
    source_order = 5,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GLAIVE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "It halves damage taken while paralysed, petrified or unconscious.",
    brand_description = "",
    colour = "LIGHTMAGENTA",
    tile = "spwpn_glaive_of_prune",
    tile_equipment = "glaive_of_prune",
    type = "",
    flags = {
        "chaotic",
    },
    properties = {
        plus = 12,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

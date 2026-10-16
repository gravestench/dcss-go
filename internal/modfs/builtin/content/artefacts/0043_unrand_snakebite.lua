-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:724

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_SNAKEBITE,
    name = "whip \"Snakebite\"",
    source_order = 43,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_WHIP,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_DEMON_WHIP,
    },
    brand = brands.VENOM,
    fallback_brand = "",
    appearance = "",
    inscription = "curare,",
    description = "",
    brand_description =
        "It occasionally inflicts asphyxiating poison on those it strikes,\ndealing poison damage and causing slown" ..
        "ess.",
    colour = "DARKGREY",
    tile = "urand_snakebite",
    tile_equipment = "snakebite",
    type = "",
    flags = {
        "poison",
    },
    properties = {
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1344

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_SPELLBINDER,
    name = "demon whip \"Spellbinder\"",
    source_order = 98,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DEMON_WHIP,
    fallback = "",
    brand = brands.ANTIMAGIC,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description =
        "It unleashes wild and unpredictable magical effects upon striking\na wizard or a creature with magical abi" ..
        "lities.",
    colour = "ETC_ENCHANT",
    tile = "urand_spellbinder",
    tile_equipment = "spellbinder",
    type = "",
    flags = {
    },
    properties = {
        plus = 5,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

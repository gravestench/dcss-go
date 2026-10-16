-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1397

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_MAJIN,
    name = "Majin-Bo",
    source_order = 102,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_QUARTERSTAFF,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_LAJATANG,
    },
    brand = brands.VAMPIRISM,
    fallback_brand = "",
    appearance = "",
    inscription = "vamp,",
    description = "Its wielder's spells cost health as well as magical power.",
    brand_description =
        "It heals its wielder for a portion of the damage dealt\nwhen they wound a living foe with it or with a spe" ..
        "ll.",
    colour = "ETC_UNHOLY",
    tile = "spwpn_majin",
    tile_equipment = "majin",
    type = "",
    flags = {
        "skip_ego",
    },
    properties = {
        int = 6,
        mp = 6,
        plus = 6,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

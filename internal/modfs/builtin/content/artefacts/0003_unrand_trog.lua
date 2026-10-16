-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:202

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_TROG,
    name = "Wrath of Trog",
    source_order = 3,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BATTLEAXE,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_EXECUTIONERS_AXE,
    },
    brand = brands.ANTIMAGIC,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description =
        "It causes slowness and exhaustion when equipped.\n+It extends the wielder's berserk rage when killing foes" ..
        ".",
    brand_description = "",
    colour = "ETC_BLOOD",
    tile = "spwpn_wrath_of_trog",
    tile_equipment = "axe_trog",
    type = "",
    flags = {
        "rampage",
    },
    properties = {
        angry = 50,
        plus = 8,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

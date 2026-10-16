-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:336

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_CEREBOV,
    name = "sword of Cerebov",
    source_order = 13,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_SWORD,
    fallback = "",
    brand = brands.FLAMING,
    fallback_brand = "",
    appearance = "great serpentine sword",
    inscription = "",
    description = "",
    brand_description = "It temporarily reduces the fire resistance of those it strikes.",
    colour = "ETC_FIRE",
    tile = "spwpn_sword_of_cerebov",
    tile_equipment = "sword_twist",
    type = "flamberge",
    flags = {
        "evil",
        "nogen",
    },
    properties = {
        base_acc = 1,
        base_dam = 1,
        plus = 6,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

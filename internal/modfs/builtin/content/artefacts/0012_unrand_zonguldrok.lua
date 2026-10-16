-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:325

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ZONGULDROK,
    name = "sword of Zonguldrok",
    source_order = 12,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DOUBLE_SWORD,
    fallback = "",
    brand = brands.REAPING,
    fallback_brand = brands.PAIN,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_BONE",
    tile = "spwpn_sword_of_zonguldrok",
    tile_equipment = "zonguldrok",
    type = "",
    flags = {
        "evil",
    },
    properties = {
        plus = 9,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

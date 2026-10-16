-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1271

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_MOON_TROLL_LEATHER_ARMOUR,
    name = "moon troll leather armour",
    source_order = 92,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_TROLL_LEATHER_ARMOUR,
    fallback = "",
    brand = armour_egos.SPIRIT_SHIELD,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_SHIMMER_BLUE",
    tile = "urand_moon_troll_leather_armour",
    tile_equipment = "moon_troll_leather_armour",
    type = "",
    flags = {
    },
    properties = {
        mp = 5,
        plus = 4,
        regen = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

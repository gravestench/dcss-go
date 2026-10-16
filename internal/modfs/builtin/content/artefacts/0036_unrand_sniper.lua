-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:629

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_SNIPER,
    name = "heavy crossbow \"Sniper\"",
    source_order = 36,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_TRIPLE_CROSSBOW,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "Acc+∞",
    description = "Any ammunition fired from it never misses its target.",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_sniper",
    tile_equipment = "sniper",
    type = "heavy crossbow",
    flags = {
        "seeinv",
    },
    properties = {
        base_delay = 4,
        plus = 9,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

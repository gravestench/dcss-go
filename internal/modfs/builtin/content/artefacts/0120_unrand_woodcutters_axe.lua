-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1625

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_WOODCUTTERS_AXE,
    name = "woodcutter's axe",
    source_order = 120,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BATTLEAXE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_woodcutters_axe",
    tile_equipment = "axe_short",
    type = "",
    flags = {
    },
    properties = {
        base_delay = -7,
        plus = 3,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 9,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

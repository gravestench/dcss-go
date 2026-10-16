-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:872

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_HOOD_ASSASSIN,
    name = "hood of the Assassin",
    source_order = 56,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = armour_egos.SEE_INVISIBLE,
    appearance = "",
    inscription = "Detection Stab+",
    description =
        "It allows the wearer to sense nearby creatures.\n+It allows the wearer to make particularly effective stab" ..
        "bing attacks against\nhelpless or unaware enemies with any weapon.",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_hood_assassin",
    tile_equipment = "hood_assassin",
    type = "",
    flags = {
    },
    properties = {
        plus = 2,
        stealth = 2,
        value = 600,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:946

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FOLLY,
    name = "robe of Folly",
    source_order = 62,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Brilliance Will-∞",
    description =
        "It increases the power of your magical spells.\n+It halves the magic cost of your spells (rounding up).\n+" ..
        "It reduces your willpower to zero.",
    brand_description = "",
    colour = "LIGHTGREY",
    tile = "urand_folly",
    tile_equipment = "robe_red2",
    type = "",
    flags = {
    },
    properties = {
        int = 8,
        plus = 4,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

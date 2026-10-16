-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1614

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DELATRAS_GLOVES,
    name = "Delatra's gloves",
    source_order = 119,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GLOVES,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "ID++",
    description =
        "It heals its wearer when they drink unknown potions.\n+It restores its wearer's MP when they read unknown " ..
        "scrolls.",
    brand_description = "",
    colour = "BLUE",
    tile = "urand_delatra",
    tile_equipment = "glove_blue",
    type = "",
    flags = {
    },
    properties = {
        plus = 1,
        value = 100,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 6,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

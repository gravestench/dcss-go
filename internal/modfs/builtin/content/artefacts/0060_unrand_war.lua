-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:928

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_WAR,
    name = "gauntlets of War",
    source_order = 60,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GLOVES,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_war",
    tile_equipment = "glove_black",
    type = "",
    flags = {
    },
    properties = {
        plus = 3,
        slay = 5,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

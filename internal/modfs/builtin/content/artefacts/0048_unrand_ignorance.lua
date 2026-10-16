-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:785

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_IGNORANCE,
    name = "tower shield of Ignorance",
    source_order = 48,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_TOWER_SHIELD,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_ignorance",
    tile_equipment = "tower_shield_of_ignorance",
    type = "",
    flags = {
    },
    properties = {
        int = -4,
        life = 1,
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

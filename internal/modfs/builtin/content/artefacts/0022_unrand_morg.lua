-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:454

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_MORG,
    name = "dagger \"Morg\"",
    source_order = 22,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DAGGER,
    fallback = "",
    brand = brands.PAIN,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_morg",
    tile_equipment = "morg",
    type = "",
    flags = {
    },
    properties = {
        int = 5,
        plus = 4,
        will = 1,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 9,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:511

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_GUARD,
    name = "glaive of the Guard",
    source_order = 27,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GLAIVE,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_BARDICHE,
    },
    brand = brands.ELECTROCUTION,
    fallback_brand = "",
    appearance = "",
    inscription = "spectral,",
    description = "",
    brand_description = "When it strikes, its spirit leaps out and fights alongside the\nwielder.",
    colour = "ETC_ELECTRICITY",
    tile = "urand_guard",
    tile_equipment = "glaive_of_the_guard",
    type = "",
    flags = {
    },
    properties = {
        ac = 5,
        plus = 5,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

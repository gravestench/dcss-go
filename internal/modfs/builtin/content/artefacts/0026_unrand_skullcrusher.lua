-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:502

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_SKULLCRUSHER,
    name = "giant club \"Skullcrusher\"",
    source_order = 26,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GIANT_CLUB,
    fallback = "",
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_skullcrusher",
    tile_equipment = "giant_club_slant",
    type = "",
    flags = {
    },
    properties = {
        plus = 3,
        str = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

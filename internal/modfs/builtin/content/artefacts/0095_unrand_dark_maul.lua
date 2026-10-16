-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1303

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DARK_MAUL,
    name = "dark maul",
    source_order = 95,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_MACE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_dark_maul",
    tile_equipment = "dark_maul",
    type = "maul",
    flags = {
    },
    properties = {
        base_acc = 2,
        base_dam = 35,
        base_delay = 13,
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

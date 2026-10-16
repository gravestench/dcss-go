-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:576

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_BOTONO,
    name = "spear of the Botono",
    source_order = 32,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SPEAR,
    fallback = "",
    brand = brands.REAPING,
    fallback_brand = brands.PAIN,
    appearance = "",
    inscription = "Hex",
    description = "",
    brand_description = "",
    colour = "ETC_UNHOLY",
    tile = "urand_botono",
    tile_equipment = "botono",
    type = "",
    flags = {
        "poison",
        "nogen",
    },
    properties = {
        hp = -6,
        life = 1,
        plus = 6,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

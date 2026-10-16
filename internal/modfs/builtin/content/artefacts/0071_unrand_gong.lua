-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1051

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_GONG,
    name = "shield of the Gong",
    source_order = 71,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_KITE_SHIELD,
    fallback = {
        class = classes.OBJ_ARMOUR,
        kind_id = item_ids.ARM_TOWER_SHIELD,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "It is deafeningly noisy when blocking attacks.",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "urand_gong",
    tile_equipment = "kite_shield_gong",
    type = "",
    flags = {
        "elec",
    },
    properties = {
        ev = -5,
        life = 1,
        plus = 18,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

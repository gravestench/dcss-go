-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1185

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_BLACK_KNIGHT_HORSE,
    name = "Black Knight's barding",
    source_order = 85,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BARDING,
    fallback = "",
    brand = armour_egos.PONDEROUSNESS,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_UNHOLY",
    tile = "urand_bk_barding",
    tile_equipment = "black_knight",
    type = "",
    flags = {
        "poison",
        "evil",
    },
    properties = {
        life = 1,
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

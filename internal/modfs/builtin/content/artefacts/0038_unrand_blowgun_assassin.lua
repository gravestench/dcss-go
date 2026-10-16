-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:654

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_BLOWGUN_ASSASSIN,
    name = "blowgun of the Assassin",
    source_order = 38,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BLOWGUN,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_LONGBOW,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "stab,",
    description = "",
    brand_description = "",
    colour = "ETC_DEATH",
    tile = "urand_blowgun",
    tile_equipment = "blowgun",
    type = "",
    flags = {
        "inv",
        "tilerim",
        "nogen",
    },
    properties = {
        plus = 6,
        stealth = 2,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

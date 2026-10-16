-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:524

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ZEALOT_SWORD,
    name = "zealot's sword",
    source_order = 28,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EUDEMON_BLADE,
    fallback = "",
    brand = brands.HOLY_WRATH,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "Whenever the wielder enters a berserk rage, their allies are\nberserked alongside them.",
    brand_description = "",
    colour = "ETC_HOLY",
    tile = "unrand_zealot_sword",
    tile_equipment = "zealot_sword",
    type = "",
    flags = {
    },
    properties = {
        angry = 20,
        ev = 3,
        life = 1,
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

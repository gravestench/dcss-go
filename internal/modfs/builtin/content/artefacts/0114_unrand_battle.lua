-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1551

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_BATTLE,
    name = "staff of Battle",
    source_order = 114,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description =
        "It enhances your conjuration magic.\n+It summons a battlesphere in combat, with strength depending on Conj" ..
        "urations\nskill.\n+Its strikes trigger the battlesphere's blasts.",
    brand_description = "",
    colour = "ETC_MAGIC",
    tile = "urand_staff_of_battle",
    tile_equipment = "battle_staff",
    type = "",
    flags = {
    },
    properties = {
        plus = 0,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

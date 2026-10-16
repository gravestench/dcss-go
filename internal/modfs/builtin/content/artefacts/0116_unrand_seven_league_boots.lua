-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1579

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_SEVEN_LEAGUE_BOOTS,
    name = "seven-league boots",
    source_order = 116,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BOOTS,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Rampage+∞",
    description = "Its wearer moves as far as possible in that direction when moving\ntowards enemies.",
    brand_description = "",
    colour = "ETC_ENCHANT",
    tile = "urand_seven_league_boots",
    tile_equipment = "seven_league_boots",
    type = "",
    flags = {
    },
    properties = {
        plus = 3,
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

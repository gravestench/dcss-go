-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:699

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_PLUTONIUM_SWORD,
    name = "plutonium sword",
    source_order = 41,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_TRIPLE_SWORD,
    fallback = "",
    brand = "",
    fallback_brand = brands.CHAOS,
    appearance = "",
    inscription = "",
    description = "",
    brand_description =
        "It occasionally inflicts wild transmutation effects on those it\nstrikes, inflicting malmutation or extra " ..
        "damage, or polymorphing them into a\nnew form.",
    colour = "ETC_MUTAGENIC",
    tile = "urand_plutonium",
    tile_equipment = "plutonium_sword",
    type = "",
    flags = {
        "mutate",
        "chaotic",
    },
    properties = {
        plus = 11,
        stealth = -1,
        value = 1000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

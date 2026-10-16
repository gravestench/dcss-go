-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1159

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DEMON_AXE,
    name = "obsidian axe",
    source_order = 83,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BROAD_AXE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = brands.PAIN,
    appearance = "",
    inscription = "Mesm",
    description =
        "Its wielder is mesmerised by any visible foes.\n+It cannot be unequipped while any foes are visible.",
    brand_description = "It occasionally summons demons to assist the wielder when it strikes\nin combat.",
    colour = "ETC_UNHOLY",
    tile = "spwpn_demon_axe",
    tile_equipment = "demon_axe",
    type = "",
    flags = {
        "evil",
        "seeinv",
        "fly",
        "drain",
    },
    properties = {
        plus = 14,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

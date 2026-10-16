-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1329

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ARC_BLADE,
    name = "arc blade",
    source_order = 97,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_RAPIER,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_QUICK_BLADE,
    },
    brand = "",
    fallback_brand = brands.ELECTROCUTION,
    appearance = "",
    inscription = "discharge,",
    description = "",
    brand_description =
        "It occasionally unleashes powerful arcs of lightning upon striking a\nfoe. These may arc to other adjacent" ..
        " creatures (including the wielder, but\ndealing reduced damage to them) before grounding out.",
    colour = "ETC_ELECTRICITY",
    tile = "urand_arc_blade",
    tile_equipment = "arc_blade",
    type = "",
    flags = {
        "elec",
    },
    properties = {
        plus = 8,
        value = 600,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

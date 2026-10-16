-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1205

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_AUTUMN_KATANA,
    name = "autumn katana",
    source_order = 87,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LONG_SWORD,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_DOUBLE_SWORD,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "vorpal, manifold assault",
    description = "It sometimes launches melee attacks against multiple visible enemies.",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_katana",
    tile_equipment = "katana_slant",
    type = "katana",
    flags = {
    },
    properties = {
        base_acc = 2,
        base_dam = 4,
        base_delay = -2,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

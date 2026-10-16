-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:297

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_CURSES,
    name = "scythe of Curses",
    source_order = 10,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_HALBERD,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_BARDICHE,
    },
    brand = brands.DRAINING,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "It inflicts powerful necromantic curses on any living foe it strikes.",
    colour = "ETC_DEATH",
    tile = "spwpn_scythe_of_curses",
    tile_equipment = "finisher",
    type = "scythe",
    flags = {
        "drain",
    },
    properties = {
        base_dam = 1,
        base_delay = 5,
        plus = 13,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

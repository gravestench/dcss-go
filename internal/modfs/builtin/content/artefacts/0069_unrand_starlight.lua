-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1025

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_STARLIGHT,
    name = "cloak of Starlight",
    source_order = 69,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CLOAK,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Dazzle",
    description = "It may blind those who miss an attack against the wearer in melee\ncombat.",
    brand_description = "",
    colour = "ETC_ICE",
    tile = "urand_starlight",
    tile_equipment = "white",
    type = "",
    flags = {
    },
    properties = {
        ev = 4,
        plus = 1,
        stealth = -2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

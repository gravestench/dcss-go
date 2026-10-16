-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1564

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_EMBRACE,
    name = "Cigotuvi's embrace",
    source_order = 115,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_LEATHER_ARMOUR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "rMiasma",
    description =
        "It gathers nearby corpses to temporarily increase the armour it\nprovides.\n+It protects you from foul pes" ..
        "tilence.",
    brand_description = "",
    colour = "ETC_UNHOLY",
    tile = "urand_cigotuvi",
    tile_equipment = "bplate_green",
    type = "",
    flags = {
        "drain",
        "evil",
        "special",
        "no_upgrade",
    },
    properties = {
        life = 1,
        plus = 4,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

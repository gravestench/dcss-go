-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1196

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_VITALITY,
    name = "amulet of Vitality",
    source_order = 86,
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_MANA_REGENERATION,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "RegenMP++",
    description = "",
    brand_description = "",
    colour = "ETC_MUTAGENIC",
    tile = "urand_vitality",
    tile_equipment = "",
    type = "",
    flags = {
        "skip_ego",
        "evil",
    },
    properties = {
        regen = 2,
        value = 1000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

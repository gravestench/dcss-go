-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:361

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ASMODEUS,
    name = "sceptre of Asmodeus",
    source_order = 15,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "ruby sceptre",
    inscription = "",
    description =
        "It can be evoked to summon fiery demons, with success rate depending\non Evocations skill. Those summoned " ..
        "this way will remain friendly only for a\nlimited time.",
    brand_description = "",
    colour = "ETC_BLOOD",
    tile = "spwpn_sceptre_of_asmodeus",
    tile_equipment = "asmodeus",
    type = "",
    flags = {
        "evil",
        "nogen",
    },
    properties = {
        plus = 7,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

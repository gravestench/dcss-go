-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1102

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_BLOODLUST,
    name = "necklace of Bloodlust",
    source_order = 76,
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "It extends the wearer's berserk rage when killing foes.",
    brand_description = "",
    colour = "ETC_BLOOD",
    tile = "urand_bloodlust",
    tile_equipment = "",
    type = "",
    flags = {
    },
    properties = {
        angry = 50,
        int = -3,
        slay = 6,
        will = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:828

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_DYROVEPREVA,
    name = "crown of Dyrovepreva",
    source_order = 52,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = armour_egos.SEE_INVISIBLE,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_JEWEL",
    tile = "urand_dyrovepreva",
    tile_equipment = "dyrovepreva",
    type = "",
    flags = {
        "elec",
        "seeinv",
    },
    properties = {
        int = 2,
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

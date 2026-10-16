-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:464

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_FINISHER,
    name = "scythe \"Finisher\"",
    source_order = 23,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_HALBERD,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_BARDICHE,
    },
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "eviscerate",
    description = "",
    brand_description =
        "It may eviscerate those it strikes, slaying them instantly, with a\ndecreasing chance against stronger foe" ..
        "s.",
    colour = "ETC_DARK",
    tile = "urand_finisher",
    tile_equipment = "finisher",
    type = "scythe",
    flags = {
    },
    properties = {
        base_dam = 1,
        base_delay = 5,
        plus = 5,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

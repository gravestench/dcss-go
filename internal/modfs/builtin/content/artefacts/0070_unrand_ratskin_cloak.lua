-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1037

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_RATSKIN_CLOAK,
    name = "ratskin cloak",
    source_order = 70,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CLOAK,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Rats",
    description = "When the wearer is hurt, rats may emerge from it to assist them.",
    brand_description = "",
    colour = "ETC_BEOGH",
    tile = "urand_ratskin_cloak",
    tile_equipment = "ratskin",
    type = "",
    flags = {
        "poison",
    },
    properties = {
        dex = 1,
        int = -1,
        life = 1,
        plus = 2,
        str = -1,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

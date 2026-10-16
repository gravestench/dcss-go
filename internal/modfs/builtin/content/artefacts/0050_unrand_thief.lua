-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:804

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_THIEF,
    name = "cloak of the Thief",
    source_order = 50,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CLOAK,
    fallback = "",
    brand = "",
    fallback_brand = armour_egos.INVISIBILITY,
    appearance = "",
    inscription = "*Fog",
    description = "It may release a thick cloud of smoke when the wearer is hurt.",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_thief",
    tile_equipment = "black",
    type = "",
    flags = {
        "seeinv",
    },
    properties = {
        plus = 2,
        slay = -2,
        stealth = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

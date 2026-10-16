-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1236

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DRAGONSKIN,
    name = "dragonskin cloak",
    source_order = 89,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CLOAK,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "opalescent scaly cloak",
    inscription = "",
    description =
        "It grants the wearer a chance to resist fire, cold, poison,\nelectricity, acid, and negative energy.",
    brand_description = "",
    colour = "ETC_HEAL",
    tile = "urand_dragonskin",
    tile_equipment = "dragonskin",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        plus = 4,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:350

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DISPATER,
    name = "staff of Dispater",
    source_order = 14,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "golden staff",
    inscription = "",
    description =
        "It can be evoked to hurl damnation at the cost of health and magic,\nwith strength depending on Evocations" ..
        " skill.",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "spwpn_staff_of_dispater",
    tile_equipment = "dispater",
    type = "",
    flags = {
        "evil",
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

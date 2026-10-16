-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1073

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_SHADOWS,
    name = "ring of Shadows",
    source_order = 73,
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.RING_STEALTH,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Umbra",
    description =
        "It surrounds you with an aura of shadow, increasing your stealth and\nreducing the accuracy of all others " ..
        "within it.",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_shadows",
    tile_equipment = "",
    type = "",
    flags = {
        "inv",
    },
    properties = {
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

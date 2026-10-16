-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:978

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_NIGHT,
    name = "robe of Night",
    source_order = 65,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Dark",
    description = "It shrouds the wearer in darkness, reducing the range at which they\ncan see and be seen by others.",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_night",
    tile_equipment = "robe_of_night",
    type = "",
    flags = {
        "seeinv",
    },
    properties = {
        plus = 5,
        value = 600,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

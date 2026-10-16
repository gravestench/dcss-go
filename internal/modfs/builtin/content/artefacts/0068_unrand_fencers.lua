-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1012

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FENCERS,
    name = "fencer's gloves",
    source_order = 68,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GLOVES,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Riposte",
    description =
        "It allows the wearer to riposte with melee\nweapons, swiftly retaliating against missed or blocked melee a" ..
        "ttacks.",
    brand_description = "",
    colour = "WHITE",
    tile = "urand_fencer",
    tile_equipment = "glove_white",
    type = "",
    flags = {
    },
    properties = {
        dex = 3,
        plus = 0,
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

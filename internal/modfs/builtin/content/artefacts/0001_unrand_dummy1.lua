-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:180

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local sentinels = require("constants.artefact_base_sentinels")

local definition = {
    id = artefact_ids.UNRAND_DUMMY1,
    name = "DUMMY UNRANDART 1",
    source_order = 1,
    class = classes.OBJ_UNASSIGNED,
    kind_id = sentinels.DUMMY_UNASSIGNED,
    fallback = {
        class = classes.OBJ_UNASSIGNED,
        kind_id = sentinels.DUMMY_UNASSIGNED,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BLACK",
    tile = "",
    tile_equipment = "",
    type = "",
    flags = {
    },
    properties = {
        plus = 250,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

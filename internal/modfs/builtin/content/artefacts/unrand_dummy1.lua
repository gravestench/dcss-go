-- DUMMY UNRANDART 1 (artefact_ids.UNRAND_DUMMY1) is a unique artefact based
-- on sentinels.DUMMY_UNASSIGNED.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local sentinels = require("constants.artefact_base_sentinels")

local definition = {
    id = artefact_ids.UNRAND_DUMMY1,
    name = "DUMMY UNRANDART 1",
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
    -- DUMMY UNRANDART 1 properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    -- The placeholder's +250 value belongs to source data; its unassigned
    -- base and mode none keep it out of normal unique generation.
    properties = {
        plus = 250,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

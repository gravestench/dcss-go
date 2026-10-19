-- DUMMY UNRANDART 2 (artefact_ids.UNRAND_DUMMY2) is a unique artefact based
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
    id = artefact_ids.UNRAND_DUMMY2,
    name = "DUMMY UNRANDART 2",
    class = classes.OBJ_UNASSIGNED,
    kind_id = sentinels.DUMMY_UNASSIGNED,
    fallback = "",
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
    -- DUMMY UNRANDART 2 properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 250,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

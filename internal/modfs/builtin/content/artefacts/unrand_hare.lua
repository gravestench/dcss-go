-- ring of the Hare (artefact_ids.UNRAND_HARE) is a unique artefact based on
-- item_ids.RING_EVASION.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_HARE,
    name = "ring of the Hare",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.RING_EVASION,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_POISON",
    tile = "urand_hare",
    tile_equipment = "",
    type = "",
    flags = {
    },
    -- ring of the Hare properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

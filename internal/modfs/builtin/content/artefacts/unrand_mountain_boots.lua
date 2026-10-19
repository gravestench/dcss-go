-- mountain boots (artefact_ids.UNRAND_MOUNTAIN_BOOTS) is a unique artefact
-- based on item_ids.ARM_BOOTS.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_MOUNTAIN_BOOTS,
    name = "mountain boots",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BOOTS,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "steadfast,",
    description = "",
    brand_description = "It prevents involuntary movement, except for blinking,\nteleportation, or banishment.",
    colour = "ETC_MOUNTAIN",
    tile = "urand_mountain",
    tile_equipment = "spider",
    type = "",
    flags = {
        "special",
    },
    -- mountain boots properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        cold = 1,
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

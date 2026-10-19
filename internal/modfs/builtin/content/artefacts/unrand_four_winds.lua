-- amulet of the Four Winds (artefact_ids.UNRAND_FOUR_WINDS) is a unique
-- artefact based on item_ids.AMU_NOTHING.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FOUR_WINDS,
    name = "amulet of the Four Winds",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_POISON",
    tile = "urand_four_winds",
    tile_equipment = "",
    type = "",
    flags = {
        "clarity",
    },
    -- amulet of the Four Winds properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        life = 1,
        will = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- ring of the Mage (artefact_ids.UNRAND_MAGE) is a unique artefact based on
-- item_ids.RING_WIZARDRY.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_MAGE,
    name = "ring of the Mage",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.RING_WIZARDRY,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_ENCHANT",
    tile = "urand_mage",
    tile_equipment = "",
    type = "",
    flags = {
        "archmagi",
    },
    -- ring of the Mage properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

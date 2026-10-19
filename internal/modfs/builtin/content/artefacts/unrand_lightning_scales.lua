-- lightning scales (artefact_ids.UNRAND_LIGHTNING_SCALES) is a unique
-- artefact based on item_ids.ARM_BARDING.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_LIGHTNING_SCALES,
    name = "lightning scales",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BARDING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "swift,",
    description = "It allows the wearer to cover ground more swiftly.",
    brand_description = "",
    colour = "ETC_ELECTRICITY",
    tile = "urand_lightning_scales",
    tile_equipment = "lightning_scales",
    type = "",
    flags = {
        "elec",
    },
    -- lightning scales properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 6,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

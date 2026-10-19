-- brooch of Shielding (artefact_ids.UNRAND_SHIELDING) is a unique artefact
-- based on item_ids.AMU_GUARDIAN_SPIRIT.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_SHIELDING,
    name = "brooch of Shielding",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_GUARDIAN_SPIRIT,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_MAGIC",
    tile = "urand_brooch_of_shielding",
    tile_equipment = "",
    type = "",
    flags = {
    },
    -- brooch of Shielding properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        sh = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

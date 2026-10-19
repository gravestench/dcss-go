-- Lear's hauberk (artefact_ids.UNRAND_LEAR) is a unique artefact based on
-- item_ids.ARM_CHAIN_MAIL.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_LEAR,
    name = "Lear's hauberk",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CHAIN_MAIL,
    fallback = {
        class = classes.OBJ_ARMOUR,
        kind_id = item_ids.ARM_PLATE_ARMOUR,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "urand_lear",
    tile_equipment = "lears_hauberk",
    type = "",
    flags = {
        "special",
    },
    -- Lear's hauberk properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 18,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

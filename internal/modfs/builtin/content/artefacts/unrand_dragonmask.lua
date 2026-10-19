-- mask of the Dragon (artefact_ids.UNRAND_DRAGONMASK) is a unique artefact
-- based on item_ids.ARM_HAT.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DRAGONMASK,
    name = "mask of the Dragon",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_SHIMMER_BLUE",
    tile = "urand_dragonmask",
    tile_equipment = "art_dragonhelm",
    type = "",
    flags = {
        "seeinv",
    },
    -- mask of the Dragon properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        slay = 3,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

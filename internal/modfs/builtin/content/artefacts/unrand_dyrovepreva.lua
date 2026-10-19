-- crown of Dyrovepreva (artefact_ids.UNRAND_DYROVEPREVA) is a unique artefact
-- based on item_ids.ARM_HAT.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_DYROVEPREVA,
    name = "crown of Dyrovepreva",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = armour_egos.SEE_INVISIBLE,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_JEWEL",
    tile = "urand_dyrovepreva",
    tile_equipment = "dyrovepreva",
    type = "",
    flags = {
        "elec",
        "seeinv",
    },
    -- crown of Dyrovepreva properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        int = 2,
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

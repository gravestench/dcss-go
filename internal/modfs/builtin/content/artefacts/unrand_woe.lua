-- Axe of Woe (artefact_ids.UNRAND_WOE) is a unique artefact based on
-- item_ids.WPN_EXECUTIONERS_AXE.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_WOE,
    name = "Axe of Woe",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EXECUTIONERS_AXE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_BLOOD",
    tile = "urand_axe_of_woe",
    tile_equipment = "axe_of_woe",
    type = "",
    flags = {
        "nogen",
        "no_upgrade",
    },
    -- Axe of Woe properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- armour of Talos (artefact_ids.UNRAND_TALOS) is a unique artefact based on
-- item_ids.ARM_PLATE_ARMOUR.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_TALOS,
    name = "armour of Talos",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_PLATE_ARMOUR,
    fallback = "",
    brand = armour_egos.PONDEROUSNESS,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_FIRE",
    tile = "urand_talos",
    tile_equipment = "talos",
    type = "",
    flags = {
        "nogen",
    },
    -- armour of Talos properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        fire = 1,
        plus = 12,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

-- captain's cutlass (artefact_ids.UNRAND_CAPTAIN) is a unique artefact based
-- on item_ids.WPN_RAPIER.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_CAPTAIN,
    name = "captain's cutlass",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_RAPIER,
    fallback = "",
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "disarm",
    description = "",
    brand_description = "It may disarm weapon-wielding foes when striking them, dealing\nextra damage in the process.",
    colour = "DARKGREY",
    tile = "urand_cutlass",
    tile_equipment = "capt_cutlass",
    type = "cutlass",
    flags = {
    },
    -- captain's cutlass properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

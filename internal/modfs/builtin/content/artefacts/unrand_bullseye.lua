-- tower shield \"Bullseye\ (artefact_ids.UNRAND_BULLSEYE) is a unique
-- artefact based on item_ids.ARM_TOWER_SHIELD.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_BULLSEYE,
    name = "tower shield \"Bullseye\"",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_TOWER_SHIELD,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "RED",
    tile = "urand_bullseye",
    tile_equipment = "kite_shield_bullseye",
    type = "",
    flags = {
        "nogen",
    },
    -- tower shield \"Bullseye\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        ev = -5,
        plus = 15,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

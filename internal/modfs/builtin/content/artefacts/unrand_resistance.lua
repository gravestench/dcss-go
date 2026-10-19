-- shield of Resistance (artefact_ids.UNRAND_RESISTANCE) is a unique artefact
-- based on item_ids.ARM_KITE_SHIELD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_RESISTANCE,
    name = "shield of Resistance",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_KITE_SHIELD,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_resistance",
    tile_equipment = "kite_shield_of_resistance",
    type = "",
    flags = {
    },
    -- shield of Resistance properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        cold = 2,
        fire = 2,
        plus = 2,
        will = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

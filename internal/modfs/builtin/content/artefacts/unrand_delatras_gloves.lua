-- Delatra's gloves (artefact_ids.UNRAND_DELATRAS_GLOVES) is a unique artefact
-- based on item_ids.ARM_GLOVES.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DELATRAS_GLOVES,
    name = "Delatra's gloves",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GLOVES,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "ID++",
    description =
        "It heals its wearer when they drink unknown potions.\n+It restores its wearer's MP when they read unknown " ..
        "scrolls.",
    brand_description = "",
    colour = "BLUE",
    tile = "urand_delatra",
    tile_equipment = "glove_blue",
    type = "",
    flags = {
    },
    -- Delatra's gloves properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 1,
        value = 100,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 6,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

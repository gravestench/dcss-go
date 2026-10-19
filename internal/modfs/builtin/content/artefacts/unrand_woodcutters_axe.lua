-- woodcutter's axe (artefact_ids.UNRAND_WOODCUTTERS_AXE) is a unique artefact
-- based on item_ids.WPN_BATTLEAXE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_WOODCUTTERS_AXE,
    name = "woodcutter's axe",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BATTLEAXE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_woodcutters_axe",
    tile_equipment = "axe_short",
    type = "",
    flags = {
    },
    -- woodcutter's axe properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        base_delay = -7,
        plus = 3,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 9,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

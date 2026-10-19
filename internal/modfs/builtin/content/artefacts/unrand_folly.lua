-- robe of Folly (artefact_ids.UNRAND_FOLLY) is a unique artefact based on
-- item_ids.ARM_ROBE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FOLLY,
    name = "robe of Folly",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Brilliance Will-∞",
    description =
        "It increases the power of your magical spells.\n+It halves the magic cost of your spells (rounding up).\n+" ..
        "It reduces your willpower to zero.",
    brand_description = "",
    colour = "LIGHTGREY",
    tile = "urand_folly",
    tile_equipment = "robe_red2",
    type = "",
    flags = {
    },
    -- robe of Folly properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        int = 8,
        plus = 4,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

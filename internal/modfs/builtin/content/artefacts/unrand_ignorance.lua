-- tower shield of Ignorance (artefact_ids.UNRAND_IGNORANCE) is a unique
-- artefact based on item_ids.ARM_TOWER_SHIELD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_IGNORANCE,
    name = "tower shield of Ignorance",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_TOWER_SHIELD,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_ignorance",
    tile_equipment = "tower_shield_of_ignorance",
    type = "",
    flags = {
    },
    -- tower shield of Ignorance properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        int = -4,
        life = 1,
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

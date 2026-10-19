-- gauntlets of War (artefact_ids.UNRAND_WAR) is a unique artefact based on
-- item_ids.ARM_GLOVES.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_WAR,
    name = "gauntlets of War",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GLOVES,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_war",
    tile_equipment = "glove_black",
    type = "",
    flags = {
    },
    -- gauntlets of War properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 3,
        slay = 5,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

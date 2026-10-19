-- robe of Night (artefact_ids.UNRAND_NIGHT) is a unique artefact based on
-- item_ids.ARM_ROBE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_NIGHT,
    name = "robe of Night",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Dark",
    description = "It shrouds the wearer in darkness, reducing the range at which they\ncan see and be seen by others.",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_night",
    tile_equipment = "robe_of_night",
    type = "",
    flags = {
        "seeinv",
    },
    -- robe of Night properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 5,
        value = 600,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition

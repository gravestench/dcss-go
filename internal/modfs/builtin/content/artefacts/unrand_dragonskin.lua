-- dragonskin cloak (artefact_ids.UNRAND_DRAGONSKIN) is a unique artefact
-- based on item_ids.ARM_CLOAK.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DRAGONSKIN,
    name = "dragonskin cloak",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CLOAK,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "opalescent scaly cloak",
    inscription = "",
    description =
        "It grants the wearer a chance to resist fire, cold, poison,\nelectricity, acid, and negative energy.",
    brand_description = "",
    colour = "ETC_HEAL",
    tile = "urand_dragonskin",
    tile_equipment = "dragonskin",
    type = "",
    flags = {
        "nogen",
    },
    -- dragonskin cloak properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 4,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
